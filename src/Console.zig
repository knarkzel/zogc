const c = @import("c.zig");
const utils = @import("utils.zig");

pub fn init(mode: *c.GXRModeObj, stdout: **anyopaque) void {
    const framebuffer = utils.framebuffer(mode);
    c.CON_Init(framebuffer, 20, 20, mode.fbWidth, mode.xfbHeight, mode.fbWidth * c.VI_DISPLAY_PIX_SZ);
    stdout.* = framebuffer;
    c.GX_CopyDisp(stdout.*, c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(stdout.*);
    c.VIDEO_Flush();
}
