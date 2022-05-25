const std = @import("std");
const Builder = std.build.Builder;

const name = "zick";
const wii_ip = "192.168.11.24";
const devkitpro = "/opt/devkitpro";

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const obj = b.addObject("main", "src/main.zig");
    obj.setOutputDir("build");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludeDir("vendor/libogc/include");
    obj.setBuildMode(mode);
    obj.setTarget(.{
        .cpu_arch = .powerpc,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.powerpc.cpu.@"750" },
        .cpu_features_add = std.Target.powerpc.featureSet(&.{.hard_float}),
    });

    const elf = b.addSystemCommand(&.{ devkitpro ++ "/devkitPPC/bin/powerpc-eabi-gcc", "build/main.o", "-g", "-DGEKKO", "-mrvl", "-mcpu=750", "-meabi", "-mhard-float", "-Wl,-Map,build/.map", "-L" ++ devkitpro ++ "/libogc/lib/wii", "-logc", "-lmad", "-o", "build/" ++ name ++ ".elf" });
    const dol = b.addSystemCommand(&.{ "elf2dol", "build/" ++ name ++ ".elf", "build/" ++ name ++ ".dol" });
    b.default_step.dependOn(&dol.step);
    dol.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    const dolphin = b.addSystemCommand(&.{ "dolphin-emu", "-a", "LLE", "-e", "build/" ++ name ++ ".dol" });
    const run_step = b.step("run", "Run in Dolphin");
    run_step.dependOn(&dol.step);
    run_step.dependOn(&dolphin.step);

    const wiiload = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/wiiload", "build/" ++ name ++ ".dol" });
    wiiload.setEnvironmentVariable("WIILOAD", "tcp:" ++ wii_ip);
    const deploy_step = b.step("deploy", "Deploy to Wii");
    deploy_step.dependOn(&dol.step);
    deploy_step.dependOn(&wiiload.step);
}
