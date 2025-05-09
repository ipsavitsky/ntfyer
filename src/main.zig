const std = @import("std");
const notif = @import("./notification.zig");

fn requestWeather(allocator: std.mem.Allocator) !void {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const location = std.http.Client.FetchOptions.Location{ .url = "http://wttr.in/Machester?format=4" };
    var body = std.ArrayList(u8).init(allocator);
    defer body.deinit();
    const res = try client.fetch(std.http.Client.FetchOptions{
        .location = location,
        .response_storage = .{ .dynamic = &body },
    });
    std.debug.print("Request complete: {s}\n{s}\n", .{ res.status.phrase() orelse "blank", body.items });
}

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // defer std.debug.assert(gpa.deinit() == .ok);

    try notif.initNotifier();
    defer notif.deinitNotifier();
    try notif.sendNotification("test", "body");
}
