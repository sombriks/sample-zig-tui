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
    // deps config
    const deps = [_][]const u8{ "zigzag", "pg" };
    for (deps) |dep| {
        exe.root_module.addImport(dep, b.dependency(dep, .{
            .target = target,
            .optimize = optimize,
        }).module(dep));
    }
    // default target: install
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
    // custom step: clean
    const clean_cmd = b.addSystemCommand(&.{ "rm", "-rf", ".zig-cache", "zig-pkg", "zig-out/" });
    const clean_step = b.step("clean", "wipe the kitchen");
    clean_step.dependOn(&clean_cmd.step);
}
