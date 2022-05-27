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
    var video = Video.init();
    console = Console.init(video.mode);

    var x: f32 = 0;
    var y: f32 = 0;
    var dx: f32 = 1;
    var dy: f32 = 1;
    while (true) {
        video.start();
        x += dx;
        y += dy;
        if (x < 0) dx = 1;
        if (x + 32 > 640) dx = -1;
        if (y < 0) dy = 1;
        if (y + 32 > 480) dy = -1;
        const points = .{ .{ x, y }, .{ x + 32, y }, .{ x + 32, y + 32 }, .{ x, y + 32 } };
        const coords = .{ .{ 0, 0 }, .{ 0.5, 0.0 }, .{ 0.5, 0.5 }, .{ 0.0, 0.5 } };
        utils.texture(points, coords);
        video.finish();
    }
}
