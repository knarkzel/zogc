const std = @import("std");
const c = @cImport({
    @cInclude("gccore.h");
});

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    c.VIDEO_Init();

    var screenMode: *c.GXRModeObj = c.VIDEO_GetPreferredMode(null);
    var xfb = c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(screenMode)) orelse unreachable;

    c.VIDEO_Configure(screenMode);
    c.VIDEO_SetNextFramebuffer(xfb);
    c.VIDEO_SetBlack(false);
    c.VIDEO_Flush();
    c.VIDEO_WaitVSync();

    const fifo_size: u32 = 256 * 1024;
    const buffer: [fifo_size]u32 = undefined;
    var fifo_buffer = c.MEM_K0_TO_K1(&buffer[0]) orelse unreachable;

    _ = c.GX_Init(fifo_buffer, fifo_size);

    c.GX_SetPixelFmt(c.GX_PF_RGB8_Z24, c.GX_ZC_LINEAR);

    c.GX_SetViewport(0, 0, @intToFloat(f32, screenMode.fbWidth), @intToFloat(f32, screenMode.efbHeight), 0, 0);

    const y_scale = c.GX_GetYScaleFactor(screenMode.xfbHeight, screenMode.efbHeight);
    _ = c.GX_SetDispCopyYScale(y_scale);

    c.GX_SetDispCopySrc(0, 0, screenMode.fbWidth, screenMode.efbHeight);
    c.GX_SetDispCopyDst(screenMode.fbWidth, screenMode.xfbHeight);

    c.GX_SetCopyFilter(screenMode.aa, &screenMode.sample_pattern, c.GX_TRUE, &screenMode.vfilter);

    c.GX_SetFieldMode(screenMode.field_rendering, @boolToInt(screenMode.viHeight == 2 * screenMode.xfbHeight));
    c.GX_SetDispCopyGamma(c.GX_GM_1_0);

    c.GX_ClearVtxDesc();
    c.GX_InvVtxCache();
    c.GX_InvalidateTexAll();

    c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);
    c.GX_SetVtxDesc(c.GX_VA_POS, c.GX_DIRECT);
    c.GX_SetVtxDesc(c.GX_VA_CLR0, c.GX_DIRECT);

    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_POS, c.GX_POS_XYZ, c.GX_F32, 0);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_TEX0, c.GX_TEX_ST, c.GX_F32, 0);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_CLR0, c.GX_CLR_RGBA, c.GX_RGBA8, 0);

    c.GX_SetZMode(c.GX_TRUE, c.GX_LEQUAL, c.GX_TRUE);

    c.GX_SetNumChans(1);
    c.GX_SetNumTexGens(1);
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);
    c.GX_SetTevOrder(c.GX_TEVSTAGE0, c.GX_TEXCOORD0, c.GX_TEXMAP0, c.GX_COLOR0A0);

    var ident: c.Mtx = undefined;
    c.guMtxIdentity(&ident);
    c.GX_LoadPosMtxImm(&ident, c.GX_PNMTX0);
    c.GX_LoadProjectionMtx(&ident, c.GX_ORTHOGRAPHIC);

    c.GX_SetViewport(0, 0, @intToFloat(f32, screenMode.fbWidth), @intToFloat(f32, screenMode.efbHeight), 0, 0);
    c.GX_SetBlendMode(c.GX_BM_BLEND, c.GX_BL_SRCALPHA, c.GX_BL_INVSRCALPHA, c.GX_LO_CLEAR);

    c.GX_SetAlphaUpdate(c.GX_TRUE);
    c.GX_SetAlphaCompare(c.GX_GREATER, 0, c.GX_AOP_AND, c.GX_ALWAYS, 0);
    c.GX_SetColorUpdate(c.GX_TRUE);
    c.GX_SetCullMode(c.GX_CULL_NONE);
    c.GX_SetClipMode(c.GX_CLIP_ENABLE);

    c.GX_SetScissor(0, 0, screenMode.fbWidth, screenMode.efbHeight);

    while (true) {
        c.GX_SetViewport(0, 0, @intToFloat(f32, screenMode.fbWidth), @intToFloat(f32, screenMode.efbHeight), 0, 0);

        // Drawing starts here
        const color = 0xFFFFFFFF;
        const points = .{ .{ -5, 0 }, .{ 5, 0 }, .{ 5, 5 } };
        triangle(points, color);

        // Drawing ends here

        c.GX_DrawDone();
        c.GX_SetZMode(c.GX_TRUE, c.GX_LEQUAL, c.GX_TRUE);
        c.GX_CopyDisp(xfb, c.GX_TRUE);

        c.VIDEO_SetNextFramebuffer(xfb);
        c.VIDEO_Flush();
        c.VIDEO_WaitVSync();
    }
}

/// Color: 0xRRGGBBAA
fn triangle(points: [3][2]f32, color: u32) void {
    c.GX_Begin(c.GX_TRIANGLES, c.GX_VTXFMT0, 3);
    for (points) |point| {
        c.GX_Position3f32(point[0], point[1], 0);
        c.GX_Color1u32(color);
    }
    c.GX_End();
}

/// Color: 0xRRGGBBAA
fn square(points: [4][2]f32, color: u32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (points) |point| {
        c.GX_Position3f32(point[0], point[1], 0);
        c.GX_Color1u32(color);
    }
    c.GX_End();
}
