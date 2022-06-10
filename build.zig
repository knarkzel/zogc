const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const allocPrint = std.fmt.allocPrint;

// user options
const name = "zogc";
const wii_ip = "192.168.11.171";
const textures = "src/game/textures";

// build options
const flags = .{ "-lmad", "-lasnd", "-logc", "-lm" };
const dolphin = switch (builtin.target.os.tag) {
    .macos => "Dolphin",
    .windows => "Dolphin.exe",
    else => "dolphin-emu",
};

pub fn build(b: *Builder) !void {
    // set build options
    const mode = b.standardReleaseOptions();
    const obj = b.addObject("main", "src/main.zig");
    obj.setOutputDir(cwd() ++ "/build");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = cwd() ++ "/libc.txt" });
    obj.addIncludeDir(cwd() ++ "/devkitpro/libogc/include");

    // target
    obj.setBuildMode(mode);
    obj.setTarget(.{
        .cpu_arch = .powerpc,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.powerpc.cpu.@"750" },
        .cpu_features_add = std.Target.powerpc.featureSet(&.{.hard_float}),
    });

    // ensure devkitpro is installed
    root().access("devkitpro", .{}) catch |err| if (err == error.FileNotFound) {
        const repository = switch (builtin.target.os.tag) {
            .macos => "https://github.com/knarkzel/devkitpro-mac",
            else => "https://github.com/knarkzel/devkitpro-linux",
        };
        try command(b.allocator, &.{ "git", "clone", repository, cwd() ++ "/devkitpro" });
    };

    // ensure images in textures are converted to tpl
    const dir = try root().openDir(textures, .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (std.mem.endsWith(u8, entry.name, ".png")) {
            const base = entry.name[0 .. entry.name.len - 4];
            const input = try allocPrint(b.allocator, "{s}/{s}", .{ textures, entry.name });
            const output = try allocPrint(b.allocator, "{s}/{s}.tpl", .{ textures, base });
            try convert(b.allocator, input, output);

            // Delete useless extra header file
            const header = try allocPrint(b.allocator, "{s}/{s}.h", .{ textures, base });
            try root().deleteFile(header);
        }
    }

    // build both elf and dol
    const elf = b.addSystemCommand(&(.{ "devkitpro/devkitPPC/bin/powerpc-eabi-gcc", "build/main.o", "-g", "-DGEKKO", "-mrvl", "-mcpu=750", "-meabi", "-mhard-float", "-Wl,-Map,build/.map", "-L" ++ "devkitpro/libogc/lib/wii" } ++ flags ++ .{ "-o", "build/" ++ name ++ ".elf" }));
    const dol = b.addSystemCommand(&.{ "devkitpro/tools/bin/elf2dol", "build/" ++ name ++ ".elf", "build/" ++ name ++ ".dol" });
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
    const wiiload = b.addSystemCommand(&.{ "devkitpro/tools/bin/wiiload", "build/" ++ name ++ ".dol" });
    wiiload.setEnvironmentVariable("WIILOAD", "tcp:" ++ wii_ip);
    deploy_step.dependOn(&dol.step);
    deploy_step.dependOn(&wiiload.step);

    // debug stack dump addresses using powerpc-eabi-addr2line
    const line_step = b.step("line", "Get line from crash address");
    line_step.dependOn(&dol.step);
    if (b.args) |args| {
        for (args) |arg| {
            const addr2line = b.addSystemCommand(&.{ "devkitpro/devkitPPC/bin/powerpc-eabi-addr2line", "-e", "build/" ++ name ++ ".elf", arg });
            line_step.dependOn(&addr2line.step);
        }
    }
}

fn root() std.fs.Dir {
    return std.fs.openDirAbsolute(cwd(), .{}) catch unreachable;
}

fn cwd() []const u8 {
    return std.fs.path.dirname(@src().file) orelse unreachable;
}

fn command(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var child = std.ChildProcess.init(argv, allocator);
    child.cwd = cwd();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}

// Converts image into tpl format
fn convert(allocator: std.mem.Allocator, input: []const u8, output: []const u8) !void {
    try command(allocator, &.{ "devkitpro/tools/bin/gxtexconv", "-i", input, "-o", output });
}
