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
    topic: []const u8,
    text: []const u8,
) !void {
    var err: ?*notify.GError = null;
    const raw_ntfy = notify.g_object_new(notify.notify_notification_get_type(), "summary", topic.ptr, "body", text.ptr, @as(?*anyopaque, null));
    const ntfy = @as(
        ?*notify.NotifyNotification,
        @ptrCast(
            @alignCast(raw_ntfy),
        ),
    );
    const res: c_int = notify.notify_notification_show(ntfy, &err);
    if (res == 0) {
        return error.FailedToPostNotification;
    }
}
