const std = @import("std");
const c = @import("c.zig");
const utils = @import("utils.zig");
const Video = @import("ogc/Video.zig");
const Gpu = @import("ogc/Gpu.zig");
const Console = @import("ogc/Console.zig");
const Pad = @import("ogc/Pad.zig");

var stdout: *anyopaque = undefined;
pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    c.GX_CopyDisp(stdout, c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(stdout);
    c.VIDEO_Flush();
    utils.print("#######################################\n# <[ PANIC ]> ");
    utils.print(message);
    utils.print(" \n#######################################");
    while (true) {}
}

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    var video = Video.init();
    Console.init(video.mode, &stdout);
    Pad.init();
    c.ASND_Init();
    @import("game/game.zig").run(&video);
}
