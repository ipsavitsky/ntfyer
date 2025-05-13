const std = @import("std");

pub const NtfyConfig = struct {
    token: []const u8,
    hostname: []const u8,
};

pub const Config = struct {
    ntfy: NtfyConfig,
    topics: []const []const u8,
};

pub fn load_config(allocator: std.mem.Allocator, path_to_config: []const u8) !Config {
    const data = try std.fs.cwd().readFileAlloc(allocator, path_to_config, 4096);
    return std.zon.parse.fromSlice(Config, allocator, @ptrCast(data), null, .{});
}
