const std = @import("std");
const c = @import("ogc/c.zig");
const utils = @import("ogc/utils.zig");
const Video = @import("ogc/Video.zig");
const Texture = @import("ogc/Texture.zig");
const Console = @import("ogc/Console.zig");
const game = @import("game.zig");

var stdout: *anyopaque = undefined;
pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    c.GX_CopyDisp(stdout, c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(stdout);
    c.VIDEO_Flush();
    utils.print(message);
    while (true) {}
}

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    var video = Video.init();
    Console.init(video.mode, &stdout);
    @import("game.zig").run(&video);
}
