const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // module config
    const exe = b.addExecutable(.{
        .name = "sample_zig_tui",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // dep config: zigzag
    exe.root_module.addImport("zigzag", b.dependency("zigzag", .{
        .target = target,
        .optimize = optimize,
    }).module("zigzag"));
    // dep config: pg
    exe.root_module.addImport("pg", b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
    }).module("pg"));
    // default target
    b.installArtifact(exe);
    // custom step: run
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    // custom step: test
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
