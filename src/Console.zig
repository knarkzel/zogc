const c = @import("c.zig");
const utils = @import("utils.zig");

const Console = @This();
framebuffer: *anyopaque,

pub fn init(mode: *c.GXRModeObj) Console {
    const framebuffer = utils.framebuffer(mode);
    c.CON_Init(framebuffer, 20, 20, mode.fbWidth, mode.xfbHeight, mode.fbWidth * c.VI_DISPLAY_PIX_SZ);
    return Console{ .framebuffer = framebuffer };
}

pub fn print(_: Console, input: [*c]const u8) void {
    _ = c.printf(input);
}
