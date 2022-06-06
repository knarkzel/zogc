const std = @import("std");
const c = @import("ogc/c.zig");
const utils = @import("ogc/utils.zig");
const Video = @import("ogc/Video.zig");
const Texture = @import("ogc/Texture.zig");
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

    // Music
    c.ASND_Init();
    c.MP3Player_Init();
    const dash = @embedFile("game/audio/drums.mp3");
    _ = c.MP3Player_PlayBuffer(dash, dash.len, null);
    @import("game/game.zig").run(&video);
}
