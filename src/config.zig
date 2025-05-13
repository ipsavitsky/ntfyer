const std = @import("std");

const Config = struct {
    ntfy_token: []const u8,
};

pub fn load_config(allocator: std.mem.Allocator) !Config {
    const data = try std.fs.cwd().readFileAlloc(allocator, "config.zon", 4096);
    return std.zon.parse.fromSlice(Config, allocator, @ptrCast(data), null, .{});
}
