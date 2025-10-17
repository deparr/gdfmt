const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const gdfmt_mod = b.addModule("gdfmt", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zd = b.dependency("zd", .{
        .target = target,
        .optimize = optimize,
    });

    gdfmt_mod.addImport("zd", zd.module("zd"));

    const gdfmt_exe = b.addExecutable(.{
        .name = "gdfmt",
        .root_module = gdfmt_mod,
    });


    const check_only = b.option(bool, "check", "check only") orelse false;

    const check_step = b.step("check", "check only");
    check_step.dependOn(&gdfmt_exe.step);

    if (check_only) {
        b.getInstallStep().dependOn(&gdfmt_exe.step);
    } else {
        b.installArtifact(gdfmt_exe);
    }
}
