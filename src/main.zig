const utils = @import("utils.zig");
const Video = @import("Video.zig");
const Console = @import("Console.zig");

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    const video = Video.init();
    const console = Console.init(video.mode);
    console.print("Hello, world\n");

    var x: f32 = 0;
    var y: f32 = 0;
    while (true) {
        video.start();
        x += 0.01;
        y -= 0.01;
        if (x > 1) x = 0;
        if (y < -1) y = 0;
        utils.triangle(.{ .{ x, y }, .{ x / 2 + 0.5, y / 2 }, .{ x / 2 + 0.5, y - 0.5 } }, 0xFFFFFFFF);
        video.finish();
    }
}
