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

    var x: f32 = 0.5;
    var y: f32 = -0.5;
    var dx: f32 = 0.01;
    var dy: f32 = 0.01;
    while (true) {
        video.start();
        const points: [3][2]f32 = .{ .{ x, y }, .{ x / 8 + 0.5, y * 2 }, .{ x / 2 + 0.5, y * 3 } };
        for (points) |point| {
            if (point[0] > 2) dx = -0.01;
            if (point[0] < 0) dx = 0.01;
            if (point[1] < -2) dy = 0.01;
            if (point[1] > 0) dy = -0.01;
        }
        x += dx;
        y += dy;
        utils.triangle(points, 0xFFFFFFFF);
        video.finish();
    }
}
