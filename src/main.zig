const std = @import("std");
const c = @import("c.zig");
const game = @import("game.zig");

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    c.VIDEO_Init();

    var screenMode: *c.GXRModeObj = c.VIDEO_GetPreferredMode(null);

    // Framebuffers
    var fbi: u8 = 0;
    var fbs: [2]*anyopaque = .{
        c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(screenMode)) orelse unreachable,
        c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(screenMode)) orelse unreachable
    };

    c.VIDEO_Configure(screenMode);
    c.VIDEO_SetNextFramebuffer(fbs[fbi]);
    c.VIDEO_SetBlack(false);
    c.VIDEO_Flush();

    const fifo_size: u32 = 256 * 1024;
    const buffer: [fifo_size]u32 = undefined;
    var fifo_buffer = c.MEM_K0_TO_K1(&buffer[0]) orelse unreachable;

    _ = c.GX_Init(fifo_buffer, fifo_size);

    const background = c.GXColor{ .r = 0, .g = 0, .b = 0, .a = 0xFF };
    c.GX_SetCopyClear(background, 0x00FFFFFF);

    const y_scale = c.GX_GetYScaleFactor(screenMode.xfbHeight, screenMode.efbHeight);
    _ = c.GX_SetDispCopyYScale(y_scale);

    c.GX_SetDispCopySrc(0, 0, screenMode.fbWidth, screenMode.efbHeight);
    c.GX_SetDispCopyDst(screenMode.fbWidth, screenMode.xfbHeight);
    c.GX_SetCopyFilter(screenMode.aa, &screenMode.sample_pattern, c.GX_TRUE, &screenMode.vfilter);
    c.GX_SetFieldMode(screenMode.field_rendering, @boolToInt(screenMode.viHeight == 2 * screenMode.xfbHeight));

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

    while (true) {
        c.GX_SetViewport(0, 0, @intToFloat(f32, screenMode.fbWidth), @intToFloat(f32, screenMode.efbHeight), 0, 0);
        game.draw(); // Draw logic
        c.GX_DrawDone();

        // Flip framebuffer
        fbi ^= 1;
        c.GX_SetZMode(c.GX_TRUE, c.GX_LEQUAL, c.GX_TRUE);
        c.GX_SetColorUpdate(c.GX_TRUE);
        c.GX_CopyDisp(fbs[fbi], c.GX_TRUE);
        c.VIDEO_SetNextFramebuffer(fbs[fbi]);
        c.VIDEO_Flush();
        c.VIDEO_WaitVSync();
    }
}
