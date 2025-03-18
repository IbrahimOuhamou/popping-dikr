// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");

    const dikr_exe_mod = b.createModule(.{ .root_source_file = b.path("src/dikr.zig"), .target = target, .optimize = optimize });
    const dikr_exe = b.addExecutable(.{ .name = "popping-dikr", .root_module = dikr_exe_mod });
    dikr_exe.linkLibrary(sdl_lib);

    const settings_exe_mod = b.createModule(.{ .root_source_file = b.path("src/settings.zig"), .target = target, .optimize = optimize });
    const settings_exe = b.addExecutable(.{ .name = "popping-dikr-settings", .root_module = settings_exe_mod });
    settings_exe.linkLibrary(sdl_lib);

    b.installArtifact(dikr_exe);
    b.installArtifact(settings_exe);

    const dikr_exe_unit_tests = b.addTest(.{ .root_module = dikr_exe_mod });
    const settings_exe_unit_tests = b.addTest(.{ .root_module = settings_exe_mod });

    const run_dikr_exe_unit_tests = b.addRunArtifact(dikr_exe_unit_tests);
    const run_settings_exe_unit_tests = b.addRunArtifact(settings_exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_dikr_exe_unit_tests.step);
    test_step.dependOn(&run_settings_exe_unit_tests.step);
}
