const c = @import("c.zig");

pub fn draw() void {
    const color = 0xFFFFFFFF;
    triangle(.{ .{ 0, 0 }, .{ 0.5, 0 }, .{ 0.5, -0.5 } }, color);
    triangle(.{ .{ 0.5, -0.5 }, .{ 1, -0.5 }, .{ 1, -1 } }, color);
    triangle(.{ .{ 1, -1 }, .{ 1.5, -1 }, .{ 1.5, -1.5 } }, color);
    triangle(.{ .{ 1.5, -1.5 }, .{ 2, -1.5 }, .{ 2, -2 } }, color);
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
