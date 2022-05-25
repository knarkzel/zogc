const c = @import("c.zig");

pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

/// Color: 0xRRGGBBAA
pub fn triangle(points: [3][2]f32, color: u32) void {
    c.GX_Begin(c.GX_TRIANGLES, c.GX_VTXFMT0, 3);
    for (points) |point| {
        c.GX_Position3f32(point[0], point[1], 0);
        c.GX_Color1u32(color);
    }
    c.GX_End();
}

/// Color: 0xRRGGBBAA
pub fn square(points: [4][2]f32, color: u32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (points) |point| {
        c.GX_Position3f32(point[0], point[1], 0);
        c.GX_Color1u32(color);
    }
    c.GX_End();
}
