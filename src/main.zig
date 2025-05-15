const std = @import("std");
const notif = @import("./notification.zig");
const conf = @import("./config.zig");

const data = struct {
    event: []const u8,
    topic: ?[]const u8 = null,
    message: ?[]const u8 = null,
};

fn subscribe_to_topic(allocator: std.mem.Allocator, ntfy_conf: conf.NtfyConfig, topic: []const u8) !void {
    var client = std.http.Client{ .allocator = allocator };
    var shb: [16 * 1024]u8 = undefined;
    const link = std.fmt.allocPrint(allocator, "http://{s}/{s}/sse", .{ ntfy_conf.hostname, topic }) catch unreachable;
    const uri = std.Uri.parse(link) catch unreachable;
    const auth_header = try std.fmt.allocPrint(allocator, "Bearer {s}", .{ntfy_conf.token});
    defer allocator.free(auth_header);
    var req = try client.open(std.http.Method.GET, uri, .{
        .server_header_buffer = &shb,
        .redirect_behavior = .unhandled,
        .headers = .{ .authorization = .{ .override = auth_header } },
        .extra_headers = &.{},
        .privileged_headers = &.{},
        .keep_alive = true,
    });
    defer req.deinit();

    try req.send();
    try req.finish();
    try req.wait();

    while (true) {
        const res = try req.reader().readUntilDelimiterAlloc(allocator, '\n', 1024);
        if (res.len == 0) continue;
        var it = std.mem.splitSequence(u8, res, ":");
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
        allocator.free(res);
    }
}

fn subscription_handler(allocator: std.mem.Allocator, ntfy_conf: conf.NtfyConfig, topic: []const u8) void {
    subscribe_to_topic(allocator, ntfy_conf, topic) catch |err| {
        std.log.err("Error in handling {s}, stopping thread: {s}", .{ topic, @errorName(err) });
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

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

    const config = try conf.load_config(allocator, config_filename);

    try notif.initNotifier();
    defer notif.deinitNotifier();

    var tp: std.Thread.Pool = undefined;
    try tp.init(.{ .allocator = allocator });
    defer tp.deinit();
    for (config.topics) |topic| {
        try tp.spawn(subscription_handler, .{ allocator, config.ntfy, topic });
    }
}
