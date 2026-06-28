const std = @import("std");

pub const NtfyConfig = struct {
    token: []const u8,
    hostname: []const u8,
};

pub const Config = struct {
    ntfy: NtfyConfig,
    topics: []const []const u8,
};

pub fn load_config(io: std.Io, allocator: std.mem.Allocator, path_to_config: []const u8) !Config {
    const data = try std.Io.Dir.cwd().readFileAlloc(io, path_to_config, allocator, std.Io.Limit.unlimited);
    return std.zon.parse.fromSlice(Config, allocator, @ptrCast(data), null, .{});
}
