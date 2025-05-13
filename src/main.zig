const std = @import("std");
const notif = @import("./notification.zig");
const conf = @import("./config.zig");

const data = struct {
    event: []const u8,
    topic: ?[]const u8 = null,
    message: ?[]const u8 = null,
};

fn subscribe_to_topic(allocator: std.mem.Allocator, token: []const u8) !void {
    var client = std.http.Client{ .allocator = allocator };
    var shb: [16 * 1024]u8 = undefined;
    const uri = std.Uri.parse("http://ntfy.savitsky.dev/test/sse") catch unreachable;
    const auth_header = try std.fmt.allocPrint(allocator, "Bearer {s}", .{token});
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
            std.log.debug("we be parsin' {s}: {s}", .{ message_data.event, message_data.message orelse "nothing" });
            if (std.mem.eql(u8, message_data.event, "message")) {
                try notif.sendNotification(message_data.topic.?, message_data.message.?);
            }
        }
        allocator.free(res);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer std.debug.assert(gpa.deinit() == .ok);

    const config = try conf.load_config(allocator);

    try notif.initNotifier();
    defer notif.deinitNotifier();

    try subscribe_to_topic(allocator, config.ntfy_token);
}
