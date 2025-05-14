const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ntfyer",
        .root_module = exe_mod,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("glib-2.0");
    exe.linkSystemLibrary("gdk-pixbuf-2.0");
    exe.linkSystemLibrary("notify");

    const aio = b.dependency("aio", .{});
    exe.root_module.addImport("coro", aio.module("coro"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
