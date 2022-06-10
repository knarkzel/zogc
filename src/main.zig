const std = @import("std");
const c = @import("c.zig");
const utils = @import("utils.zig");
const Gpu = @import("ogc/Gpu.zig");
const Pad = @import("ogc/Pad.zig");
const Video = @import("ogc/Video.zig");

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    Pad.init();
    var video = Video.init();
    @import("game/game.zig").run(&video) catch |err| @panic(@errorName(err));
}
