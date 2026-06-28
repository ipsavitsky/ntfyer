const std = @import("std");
const notif = @import("./notification.zig");
const conf = @import("./config.zig");

const data = struct {
    event: []const u8,
    topic: ?[]const u8 = null,
    message: ?[]const u8 = null,
};

fn subscribe_to_topic(allocator: std.mem.Allocator, io: std.Io, ntfy_conf: conf.NtfyConfig, topic: []const u8) !void {
    var client = std.http.Client{ .allocator = allocator, .io = io };
    defer client.deinit();
    const link = std.fmt.allocPrint(allocator, "http://{s}/{s}/sse", .{ ntfy_conf.hostname, topic }) catch unreachable;
    defer allocator.free(link);
    const uri = std.Uri.parse(link) catch unreachable;
    const auth_header = try std.fmt.allocPrint(allocator, "Bearer {s}", .{ntfy_conf.token});
    defer allocator.free(auth_header);
    var req = try client.request(std.http.Method.GET, uri, .{
        .redirect_behavior = .unhandled,
        .headers = .{ .authorization = .{ .override = auth_header } },
        .extra_headers = &.{},
        .privileged_headers = &.{},
        .keep_alive = true,
    });
    defer req.deinit();

    try req.sendBodiless();
    var response = try req.receiveHead(&.{});
    if (response.head.status != .ok) {
        return error.UnexpectedStatus;
    }

    std.log.debug("response: {s}", .{response.head.bytes});

    var reader_buffer: [16 * 1024]u8 = undefined;
    var body_reader = response.reader(&reader_buffer);

    while (true) {
        const line = try body_reader.takeDelimiter('\n');
        const actual_line = line.?;
        std.log.info("Received message: {s}", .{actual_line});
        if (actual_line.len == 0) continue;
        var it = std.mem.splitSequence(u8, actual_line, ":");
        const prefix = it.next() orelse continue;
        const rest = it.rest();
        std.log.info("{s}{s}", .{ prefix, rest });
        if (std.mem.eql(u8, prefix, "data")) {
            std.log.debug("parsing data", .{});
            const val = try std.json.parseFromSlice(data, allocator, rest, .{
                .ignore_unknown_fields = true,
            });
            const message_data = val.value;
            defer val.deinit();
            std.log.debug("parsing message {s}: {s}", .{ message_data.event, message_data.message orelse "" });
            if (std.mem.eql(u8, message_data.event, "message")) {
                try notif.sendNotification(allocator, message_data.topic.?, message_data.message.?);
            }
        }
    }
}

fn subscription_handler(allocator: std.mem.Allocator, io: std.Io, ntfy_conf: conf.NtfyConfig, topic: []const u8) void {
    while (true) {
        subscribe_to_topic(allocator, io, ntfy_conf, topic) catch |err| {
            std.log.err("Error in handling {s} thread: {s}", .{ topic, @errorName(err) });
        };
        io.sleep(std.Io.Duration.fromSeconds(10), std.Io.Clock.real) catch unreachable;
    }
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var args = init.minimal.args.iterate();

    _ = args.next();

    var config_filename: []const u8 = "config.zon";

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-c")) {
            config_filename = args.next() orelse unreachable;
        } else {
            std.log.warn("Unknown argument: {s}", .{arg});
        }
    }
    std.log.debug("config filename: {s}", .{config_filename});

    const config = try conf.load_config(io, gpa, config_filename);

    try notif.initNotifier();
    defer notif.deinitNotifier();

    var tp: std.Io.Threaded = .init(gpa, .{});
    defer tp.deinit();
    const tp_io = tp.io();

    const futures = try gpa.alloc(std.Io.Future(void), config.topics.len);
    defer gpa.free(futures);

    for (config.topics, futures) |topic, *future| {
        future.* = try tp_io.concurrent(subscription_handler, .{ gpa, io, config.ntfy, topic });
    }

    for (futures) |*future| {
        _ = future.await(tp_io);
    }
}
