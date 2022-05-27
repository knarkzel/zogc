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

    // Audio
    const sample_ogg = &struct {
        var bytes = @embedFile("sample.ogg").*;
    }.bytes;
    // const sample_ogg = &struct { bytes @embedFile("sample.ogg");
    _ = c.PlayOgg(sample_ogg, sample_ogg.len, 5, c.OGG_ONE_TIME);

    while (true) {
        video.start();
        utils.triangle(.{ .{ 10, 10 }, .{ 210, 10 }, .{ 210, 210 } }, .{ 1, 1, 1 });
        video.finish();
    }
}
