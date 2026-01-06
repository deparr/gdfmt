const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const run_step = b.step("run", "run the program");
    const test_step = b.step("test", "run tests");
    const rdi_step = b.step("rdi", "generate rdi");

    // const zd = b.dependency("zd", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    const gdfmt_exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const gdfmt_exe = b.addExecutable(.{
        .root_module = gdfmt_exe_mod,
        .name = "gdfmt",
    });
    const install_gdfmt = b.addInstallArtifact(gdfmt_exe, .{});
    b.getInstallStep().dependOn(&install_gdfmt.step);

    const run_radbin = b.addSystemCommand(&.{
        "radbin",
        "./zig-out/bin/gdfmt.pdb",
        "--out:./zig-out/bin/gdfmt.rdi",
    });
    run_radbin.step.dependOn(&install_gdfmt.step);
    rdi_step.dependOn(&run_radbin.step);

    const run = b.addRunArtifact(gdfmt_exe);
    if (b.args) |args| {
        run.addArgs(args);
    }
    run_step.dependOn(&run.step);

    const gdscript_core_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gdscript.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_test = b.addRunArtifact(gdscript_core_test);
    test_step.dependOn(&run_test.step);
}
