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

    while (true) {
        video.start();
        utils.triangle(.{ .{ 10, 10 }, .{ 210, 10 }, .{ 210, 210 } }, .{ 1, 1, 1 });
        video.finish();
    }
}
