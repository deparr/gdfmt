const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const run_step = b.step("run", "run the program");
    // const test_step = b.step("test", "run tests");

    // const zd = b.dependency("zd", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    const gdfmt_exe = b.addExecutable(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .name = "gdfmt",
    });
    b.installArtifact(gdfmt_exe);

    const run = b.addRunArtifact(gdfmt_exe);
    if (b.args) |args| {
        run.addArgs(args);
    }
    run_step.dependOn(&run.step);
}
