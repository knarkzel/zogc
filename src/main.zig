const c = @import("c.zig");
const std = @import("std");
const utils = @import("utils.zig");
const Video = @import("Video.zig");
const Console = @import("Console.zig");

var console: *anyopaque = undefined;

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    c.GX_CopyDisp(console, c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(console);
    c.VIDEO_Flush();
    utils.print("PANIC!\n");
    utils.print(message);
    while (true) {}
}

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    const video = Video.init();
    console = Console.init(video.mode);

    var x: f32 = 0;
    var y: f32 = 0;
    var it: u8 = 0;
    while (true) {
        video.start();
        it += 1;
        x += 0.01;
        y -= 0.01;
        if (x > 1) x = 0;
        if (y < -1) y = 0;
        utils.triangle(.{ .{ x, y }, .{ x / 2 + 0.5, y / 2 }, .{ x / 2 + 0.5, y - 0.5 } }, 0xFFFFFFFF);
        video.finish();
    }
}
