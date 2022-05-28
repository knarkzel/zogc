const c = @import("c.zig");
const std = @import("std");
const utils = @import("utils.zig");
const Video = @import("Video.zig");
const Texture = @import("Texture.zig");

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    var video = Video.init();
    var texture = Texture.init();
    texture.load_tpl("textures.tpl", 0);

    while (true) {
        video.start();
        const points = utils.rectangle(0, 0, 32, 32);
        const coords = utils.rectangle(0, 0, 0.5, 0.5);
        utils.texture(points, coords);
        video.finish();
    }
}
