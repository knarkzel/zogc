const c = @import("c.zig");
const std = @import("std");
const utils = @import("utils.zig");
const Video = @import("Video.zig");
const Audio = @import("Audio.zig");
const Texture = @import("Texture.zig");
const Console = @import("Console.zig");

var stdout: *anyopaque = undefined;
pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    c.GX_CopyDisp(stdout, c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(stdout);
    c.VIDEO_Flush();
    utils.print(message);
    while (true) {}
}

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    var video = Video.init();
    Console.init(video.mode, &stdout);

    // Texture
    var texture = Texture.init();
    texture.load_tpl("../assets/textures.tpl", 0);

    // Music
    var audio = Audio.init();
    audio.load_ogg("../assets/sample.ogg", .infinite_time);

    while (true) {
        video.start();
        const points = utils.rectangle(0, 0, 32, 32);
        const coords = utils.rectangle(0, 0, 0.5, 0.5);
        utils.texture(points, coords);
        video.finish();
    }
}
