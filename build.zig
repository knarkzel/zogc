const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;

const name = "zick";
const wii_ip = "192.168.11.171";
const devkitpro = "/opt/devkitpro";
const dolphin = switch (builtin.target.os.tag) {
    .macos => "/Applications/Dolphin.app/Contents/MacOS/Dolphin",
    else => "dolphin-emu",
};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const obj = b.addObject("main", "src/main.zig");
    obj.setOutputDir("build");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludeDir("vendor/libogc/include");

    // target
    obj.setBuildMode(mode);
    obj.setTarget(.{
        .cpu_arch = .powerpc,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.powerpc.cpu.@"750" },
        .cpu_features_add = std.Target.powerpc.featureSet(&.{.hard_float}),
    });

    const elf = b.addSystemCommand(&.{ devkitpro ++ "/devkitPPC/bin/powerpc-eabi-gcc", "build/main.o", "-g", "-DGEKKO", "-mrvl", "-mcpu=750", "-meabi", "-mhard-float", "-Wl,-Map,build/.map", "-L" ++ devkitpro ++ "/libogc/lib/wii", "-L" ++ devkitpro ++ "/portlibs/ppc/lib", "-lmad", "-lasnd", "-logc", "-lm", "-o", "build/" ++ name ++ ".elf" });
    const dol = b.addSystemCommand(&.{ "elf2dol", "build/" ++ name ++ ".elf", "build/" ++ name ++ ".dol" });
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

    const conv_step = b.step("tpl", "Converts image into tpl");
    var buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const cwd = try std.os.getcwd(&buffer);
    if (b.args) |args| {
        for (args) |arg| {
            const path = b.pathJoin(&.{ cwd, "/", arg });
            const gxtexconv = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/gxtexconv", "-i", path });
            conv_step.dependOn(&gxtexconv.step);
        }
    }
}
