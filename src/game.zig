const c = @import("c.zig");

var x: f32 = 0;
var y: f32 = 0;

pub fn draw() void {
    x += 0.01;
    y -= 0.01;
    if (x > 1) x = 0;
    if (y < -1) y = 0;
    triangle(.{ .{ x, y }, .{ x / 2 + 0.5, y / 2 }, .{ x / 2 + 0.5, y - 0.5 } }, 0xFFFFFFFF);
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
