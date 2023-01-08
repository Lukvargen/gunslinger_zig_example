const std = @import("std");

pub fn build(b: *std.build.Builder) void {

    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("first", "src/main.zig");

    exe.linkSystemLibrary("c");
    exe.linkLibC();

    if (target.isWindows()) {
        exe.addCSourceFile("c_include/gs_impl.c", &[_][]const u8{"-fno-sanitize=undefined"});

        exe.linkSystemLibrary("opengl32");
        exe.linkSystemLibrary("kernel32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("shell32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("Winmm");
        exe.linkSystemLibrary("Advapi32");
    } else if (target.isLinux()) {
        exe.addCSourceFile("c_include/gs_impl.c", &[_][]const u8{"-fno-sanitize=undefined", "-std=gnu99", "-pthread"});

        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("Xi");
        exe.linkSystemLibrary("m");
        exe.linkSystemLibrary("GL");
    }

    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addIncludePath("c_include");
    exe.addIncludePath("third_party/include");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
