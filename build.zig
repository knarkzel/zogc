const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const allocPrint = std.fmt.allocPrint;

const name = "zogc";
const wii_ip = "192.168.11.171";
const textures = "src/game/textures";
const packages = "vendor";
const devkitpro = packages ++ "/devkitpro";
const dolphin = switch (builtin.target.os.tag) {
    .macos => "Dolphin",
    .windows => "Dolphin.exe",
    else => "dolphin-emu",
};

pub fn build(b: *Builder) !void {
    // set build options
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

    // ensure dependencies are installed
    {
        const dir = try std.fs.cwd().openDir(packages, .{ .iterate = true });
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            const module = try allocPrint(b.allocator, "{s}/{s}", .{ packages, entry.name });
            try package(b.allocator, module);
        }
    }

    // ensure images in textures are converted to tpl
    {
        const dir = try std.fs.cwd().openDir(textures, .{ .iterate = true });
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (std.mem.endsWith(u8, entry.name, ".png")) {
                const base = entry.name[0 .. entry.name.len - 4];
                const input = try allocPrint(b.allocator, "{s}/{s}", .{ textures, entry.name });
                const output = try allocPrint(b.allocator, "{s}/{s}.tpl", .{ textures, base });
                try convert(b.allocator, input, output);

                // Delete useless extra header file
                const header = try allocPrint(b.allocator, "{s}/{s}.h", .{ textures, base });
                try std.fs.cwd().deleteFile(header);
            }
        }
    }

    // build both elf and dol
    const elf = b.addSystemCommand(&.{ devkitpro ++ "/devkitPPC/bin/powerpc-eabi-gcc", "build/main.o", "-g", "-DGEKKO", "-mrvl", "-mcpu=750", "-meabi", "-mhard-float", "-Wl,-Map,build/.map", "-L" ++ devkitpro ++ "/libogc/lib/wii", "-lmad", "-lasnd", "-logc", "-lm", "-o", "build/" ++ name ++ ".elf" });
    const dol = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/elf2dol", "build/" ++ name ++ ".elf", "build/" ++ name ++ ".dol" });
    b.default_step.dependOn(&dol.step);
    dol.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    // run dol in dolphin
    const run_step = b.step("run", "Run in Dolphin");
    const emulator = b.addSystemCommand(&.{ dolphin, "-a", "LLE", "-e", "build/" ++ name ++ ".dol" });
    run_step.dependOn(&dol.step);
    run_step.dependOn(&emulator.step);

    // deploy dol to wii over network
    const deploy_step = b.step("deploy", "Deploy to Wii");
    const wiiload = b.addSystemCommand(&.{ devkitpro ++ "/tools/bin/wiiload", "build/" ++ name ++ ".dol" });
    wiiload.setEnvironmentVariable("WIILOAD", "tcp:" ++ wii_ip);
    deploy_step.dependOn(&dol.step);
    deploy_step.dependOn(&wiiload.step);

    // debug stack dump addresses using powerpc-eabi-addr2line
    const line_step = b.step("line", "Get line from crash address");
    line_step.dependOn(&dol.step);
    if (b.args) |args| {
        for (args) |arg| {
            const addr2line = b.addSystemCommand(&.{ devkitpro ++ "/devkitPPC/bin/powerpc-eabi-addr2line", "-e", "build/" ++ name ++ ".elf", arg });
            line_step.dependOn(&addr2line.step);
        }
    }
}

fn command(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var child = std.ChildProcess.init(argv, allocator);
    child.cwd = std.fs.path.dirname(@src().file) orelse ".";
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}

// Ensures package is installed with git submodule
fn package(allocator: std.mem.Allocator, path: []const u8) !void {
    try command(allocator, &.{ "git", "submodule", "update", "--init", "--recursive", path });
}

// Converts image into tpl format
fn convert(allocator: std.mem.Allocator, input: []const u8, output: []const u8) !void {
    try command(allocator, &.{ devkitpro ++ "/tools/bin/gxtexconv", "-i", input, "-o", output });
}
