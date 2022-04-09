const std = @import("std");
const c = @cImport({
    @cInclude("gccore.h");
});

const fifo_size: u32 = 256 * 1024;
var screenMode: *c.GXRModeObj = undefined;
var frameBuffer: *anyopaque = undefined;

var vertices: [9]i16 align(32) = [9]i16{ 0, 15, 0, -15, -15, 0, 15, -15, 0 };

var colors: [12]u8 align(32) = [12]u8{
    255, 0, 0, 255, // red
    0, 255, 0, 255, // green
    0, 0, 255, 255, // blue
};

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    var view: c.Mtx = undefined;
    var projection: c.Mtx = undefined;
    var fifo_buffer: *anyopaque = undefined;

    c.VIDEO_Init();

    screenMode = c.VIDEO_GetPreferredMode(null);

    var xfb = c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(screenMode)) orelse unreachable;

    c.VIDEO_Configure(screenMode);
    c.VIDEO_SetNextFramebuffer(xfb);
    c.VIDEO_SetBlack(false);
    c.VIDEO_Flush();

    var buffer: [fifo_size]u32 = undefined;
    fifo_buffer = c.MEM_K0_TO_K1(&buffer[0]) orelse unreachable;

    _ = c.GX_Init(fifo_buffer, fifo_size);
    c.GX_SetViewport(0, 0, @intToFloat(f32, screenMode.fbWidth), @intToFloat(f32, screenMode.efbHeight), 0, 1);
    _ = c.GX_SetDispCopyYScale(@intToFloat(f32, screenMode.xfbHeight) / @intToFloat(f32, screenMode.efbHeight));
    c.GX_SetScissor(0, 0, screenMode.fbWidth, screenMode.efbHeight);
    c.GX_SetDispCopySrc(0, 0, screenMode.fbWidth, screenMode.efbHeight);
    c.GX_SetDispCopyDst(screenMode.fbWidth, screenMode.xfbHeight);
    c.GX_SetCopyFilter(screenMode.aa, &screenMode.sample_pattern, c.GX_TRUE, &screenMode.vfilter);
    c.GX_SetFieldMode(screenMode.field_rendering, @boolToInt(screenMode.viHeight == 2 * screenMode.xfbHeight));

    c.GX_SetCullMode(c.GX_CULL_NONE);
    c.GX_CopyDisp(xfb, c.GX_TRUE);
    c.GX_SetDispCopyGamma(c.GX_GM_1_0);

    var camera = c.guVector{ .x = 0.0, .y = 0.0, .z = 0.0 };
    var up = c.guVector{ .x = 0.0, .y = 1.0, .z = 0.0 };
    var look = c.guVector{ .x = 0.0, .y = 0.0, .z = -1.0 };

    c.guPerspective(&projection, 60, 1.33, 10.0, 300.0);
    c.GX_LoadProjectionMtx(&projection, c.GX_PERSPECTIVE);

    c.GX_ClearVtxDesc();
    c.GX_SetVtxDesc(c.GX_VA_POS, c.GX_INDEX8);
    c.GX_SetVtxDesc(c.GX_VA_CLR0, c.GX_INDEX8);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_POS, c.GX_POS_XYZ, c.GX_S16, 0);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_CLR0, c.GX_CLR_RGBA, c.GX_RGBA8, 0);
    c.GX_SetArray(c.GX_VA_POS, &vertices, 3 * @sizeOf(i16));
    c.GX_SetArray(c.GX_VA_CLR0, &colors, 4 * @sizeOf(u8));
    c.GX_SetNumChans(1);
    c.GX_SetNumTexGens(0);
    c.GX_SetTevOrder(c.GX_TEVSTAGE0, c.GX_TEXCOORDNULL, c.GX_TEXMAP_NULL, c.GX_COLOR0A0);
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);

    while (true) {
        c.guLookAt(&view, &camera, &up, &look);
        c.GX_SetViewport(0, 0, @intToFloat(f32, screenMode.fbWidth), @intToFloat(f32, screenMode.efbHeight), 0, 1);
        c.GX_InvVtxCache();
        c.GX_InvalidateTexAll();

        var model: c.Mtx = undefined;

        c.guMtxIdentity(&model);
        c.guMtxTransApply(&model, &model, 0.0, 0.0, -50.0);
        c.guMtxConcat(&view, &model, &model);

        c.GX_LoadPosMtxImm(&model, c.GX_PNMTX0);

        c.GX_Begin(c.GX_TRIANGLES, c.GX_VTXFMT0, 3);

        c.GX_Position1x8(0);
        c.GX_Color1x8(0);
        c.GX_Position1x8(1);
        c.GX_Color1x8(1);
        c.GX_Position1x8(2);
        c.GX_Color1x8(2);

        c.GX_End();

        c.GX_DrawDone();
        c.GX_SetZMode(c.GX_TRUE, c.GX_LEQUAL, c.GX_TRUE);
        c.GX_SetColorUpdate(c.GX_TRUE);
        c.GX_CopyDisp(xfb, c.GX_TRUE);
        c.GX_Flush();

        c.VIDEO_WaitVSync();
    }
}
