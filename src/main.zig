const c = @import("c.zig");
const std = @import("std");
const utils = @import("utils.zig");
const Video = @import("Video.zig");
const Console = @import("Console.zig");

var stdout: *anyopaque = undefined;
pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    c.GX_CopyDisp(stdout, c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(stdout);
    c.VIDEO_Flush();
    utils.print("PANIC!\n");
    utils.print(message);
    while (true) {}
}

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    const video = Video.init();
    Console.init(video.mode, &stdout);

    // MP3
    const sample_mp3 = @embedFile("sample.mp3");
    _ = c.MP3Player_PlayBuffer(sample_mp3, sample_mp3.len, null);

    while (true) {
        video.start();
        utils.triangle(.{ .{ 10, 10 }, .{ 210, 10 }, .{ 210, 210 } }, .{ 1, 1, 1 });
        video.finish();
    }
}
