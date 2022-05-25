const c = @import("c.zig");
const utils = @import("utils.zig");

const Video = @This();
mode: *c.GXRModeObj,
framebuffers: [2]*anyopaque,

// Other globals
var fbi: u8 = 0;

pub fn init() Video {
    c.VIDEO_Init();
    var mode: *c.GXRModeObj = c.VIDEO_GetPreferredMode(null);
    var fbs: [2]*anyopaque = .{ utils.framebuffer(mode), utils.framebuffer(mode) };
    c.VIDEO_Configure(mode);
    c.VIDEO_SetNextFramebuffer(fbs[fbi]);
    c.VIDEO_SetBlack(false);
    c.VIDEO_Flush();

    const fifo_size: u32 = 256 * 1024;
    const buffer: [fifo_size]u32 = undefined;
    var fifo_buffer = c.MEM_K0_TO_K1(&buffer[0]) orelse unreachable;

    _ = c.GX_Init(fifo_buffer, fifo_size);

    const background = c.GXColor{ .r = 0, .g = 0, .b = 0, .a = 0xFF };
    c.GX_SetCopyClear(background, 0x00FFFFFF);

    const y_scale = c.GX_GetYScaleFactor(mode.xfbHeight, mode.efbHeight);
    _ = c.GX_SetDispCopyYScale(y_scale);

    c.GX_SetDispCopySrc(0, 0, mode.fbWidth, mode.efbHeight);
    c.GX_SetDispCopyDst(mode.fbWidth, mode.xfbHeight);
    c.GX_SetCopyFilter(mode.aa, &mode.sample_pattern, c.GX_TRUE, &mode.vfilter);
    c.GX_SetFieldMode(mode.field_rendering, @boolToInt(mode.viHeight == 2 * mode.xfbHeight));

    c.GX_InvVtxCache();
    c.GX_ClearVtxDesc();

    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);
    c.GX_SetVtxDesc(c.GX_VA_POS, c.GX_DIRECT);
    c.GX_SetVtxDesc(c.GX_VA_CLR0, c.GX_DIRECT);

    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_POS, c.GX_POS_XYZ, c.GX_F32, 0);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_TEX0, c.GX_TEX_ST, c.GX_F32, 0);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_CLR0, c.GX_CLR_RGBA, c.GX_RGBA8, 0);

    c.GX_SetNumChans(1);
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);

    // [0, 0] -> origin
    var matrix: c.Mtx = undefined;
    c.guMtxIdentity(&matrix);
    matrix[0][3] = -0.5;
    matrix[1][3] = 0.5;

    c.GX_LoadPosMtxImm(&matrix, c.GX_PNMTX0);
    c.GX_LoadProjectionMtx(&matrix, c.GX_ORTHOGRAPHIC);
    return Video{ .mode = mode, .framebuffers = fbs };
}

pub fn start(self: Video) void {
    c.GX_SetViewport(0, 0, @intToFloat(f32, self.mode.fbWidth), @intToFloat(f32, self.mode.efbHeight), 0, 0);
}

pub fn finish(self: Video) void {
    c.GX_DrawDone();
    fbi ^= 1;
    c.GX_SetZMode(c.GX_TRUE, c.GX_LEQUAL, c.GX_TRUE);
    c.GX_SetColorUpdate(c.GX_TRUE);
    c.GX_CopyDisp(self.framebuffers[fbi], c.GX_TRUE);
    c.VIDEO_SetNextFramebuffer(self.framebuffers[fbi]);
    c.VIDEO_Flush();
    c.VIDEO_WaitVSync();
}
