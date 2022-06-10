const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;

const name = "zogc";
const wii_ip = "192.168.11.171";
const devkitpro = "vendor/devkitpro";
const dolphin = switch (builtin.target.os.tag) {
    .macos => "Dolphin",
    .windows => "Dolphin.exe",
    else => "dolphin-emu",
};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const obj = b.addObject("main", "src/main.zig");
    obj.setOutputDir("build");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludeDir(devkitpro ++ "/libogc/include");

    // target
    obj.setBuildMode(mode);
    obj.setTarget(.{
        .cpu_arch = .powerpc,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.powerpc.cpu.@"750" },
        .cpu_features_add = std.Target.powerpc.featureSet(&.{.hard_float}),
    });

    // ensure depencies in vendor are installed
    const vendor = "vendor";
    const dir = try std.fs.cwd().openDir(vendor, .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        const module = try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ vendor, entry.name });
        try package(b.allocator, module);
    }

    const elf = b.addSystemCommand(&.{ devkitpro ++ "/devkitPPC/bin/powerpc-eabi-gcc", "build/main.o", "-g", "-DGEKKO", "-mrvl", "-mcpu=750", "-meabi", "-mhard-float", "-Wl,-Map,build/.map", "-L" ++ devkitpro ++ "/libogc/lib/wii", "-lmad", "-lasnd", "-logc", "-lm", "-o", "build/" ++ name ++ ".elf" });
    const dol = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/elf2dol", "build/" ++ name ++ ".elf", "build/" ++ name ++ ".dol" });
    b.default_step.dependOn(&dol.step);
    dol.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    const run_step = b.step("run", "Run in Dolphin");
    const emulator = b.addSystemCommand(&.{ dolphin, "-a", "LLE", "-e", "build/" ++ name ++ ".dol" });
    run_step.dependOn(&dol.step);
    run_step.dependOn(&emulator.step);

    const deploy_step = b.step("deploy", "Deploy to Wii");
    const wiiload = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/wiiload", "build/" ++ name ++ ".dol" });
    wiiload.setEnvironmentVariable("WIILOAD", "tcp:" ++ wii_ip);
    deploy_step.dependOn(&dol.step);
    deploy_step.dependOn(&wiiload.step);

    const line_step = b.step("line", "Get line from crash address");
    line_step.dependOn(&dol.step);
    if (b.args) |args| {
        for (args) |arg| {
            const addr2line = b.addSystemCommand(&.{ devkitpro ++ "/devkitPPC/bin/powerpc-eabi-addr2line", "-e", "build/" ++ name ++ ".elf", arg });
            line_step.dependOn(&addr2line.step);
        }
    }

    // const conv_step = b.step("tpl", "Converts image into tpl");
    // if (b.args) |args| {
    // for (args) |arg| {
    // const path = b.pathJoin(&.{ cwd(), "/", arg });
    // const gxtexconv = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/gxtexconv", "-i", path });
    // conv_step.dependOn(&gxtexconv.step);
    // }
    // }
}

// Ensures package is installed with git submodule
fn package(allocator: std.mem.Allocator, path: []const u8) !void {
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = std.fs.path.dirname(@src().file) orelse ".";
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}
