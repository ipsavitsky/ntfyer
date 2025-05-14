const std = @import("std");
const notify = @cImport({
    @cDefine("__LIBC", "");
    @cInclude("libnotify/notify.h");
});

pub fn initNotifier() !void {
    const res: c_int = notify.notify_init("ntfyer");
    if (res == 0) {
        return error.FailedToInitNotify;
    }
}

pub fn deinitNotifier() void {
    notify.notify_uninit();
}

pub fn sendNotification(
    allocator: std.mem.Allocator,
    topic: []const u8,
    text: []const u8,
) !void {
    var err: ?*notify.GError = null;
    const topicZ = allocator.dupeZ(u8, topic) catch unreachable;
    defer allocator.free(topicZ);
    const textZ = allocator.dupeZ(u8, text) catch unreachable;
    defer allocator.free(textZ);
    const raw_ntfy = notify.g_object_new(notify.notify_notification_get_type(), "summary", topicZ.ptr, "body", textZ.ptr, @as(?*anyopaque, null));
    const res: c_int = notify.notify_notification_show(@ptrCast(@alignCast(raw_ntfy)), &err);
    if (res == 0) {
        return error.FailedToPostNotification;
    }
}
