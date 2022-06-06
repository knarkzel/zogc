const c = @import("c.zig");

pub const Rectangle = [4][2]f32;

pub fn framebuffer(mode: *c.GXRModeObj) *anyopaque {
    return c.MEM_K0_TO_K1(c.SYS_AllocateFramebuffer(mode)) orelse unreachable;
}

pub fn print(input: []const u8) void {
    _ = c.printf(@ptrCast([*c]const u8, input));
}

// Draw triangle from points and color
pub fn triangle(points: [3][2]f32, color: [3]f32) void {
    c.GX_Begin(c.GX_TRIANGLES, c.GX_VTXFMT0, 3);
    for (points) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color3f32(color[0], color[1], color[2]);
    }
    c.GX_End();
}

// Draw square from points and color
pub fn square(points: [4][2]f32, color: [3]f32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    for (points) |point| {
        c.GX_Position2f32(point[0], point[1]);
        c.GX_Color3f32(color[0], color[1], color[2]);
    }
    c.GX_End();
}

// Draw texture from points and texture coordinates
pub fn texture(points: [4][2]f32, coords: [4][2]f32) void {
    c.GX_Begin(c.GX_QUADS, c.GX_VTXFMT0, 4);
    var i: u8 = 0;
    while (i < 4) {
        c.GX_Position2f32(points[i][0], points[i][1]);
        c.GX_TexCoord2f32(coords[i][0], coords[i][1]);
        i += 1;
    }
    c.GX_End();
}

// Draw sprite
pub fn sprite(area: [4][2]f32, coord: [2]f32, width: f32, height: f32) void {
    const points = rectangle(area[0][0], area[0][1], area[1][0] - area[0][0], area[2][1] - area[0][1]);
    const coords = rectangle(coord[0] / (width / 32), coord[1] / (height / 32), 32 / width, 32 / height);
    texture(points, coords);
}

pub fn rectangle(x: f32, y: f32, width: f32, height: f32) [4][2]f32 {
    return .{ .{ x, y }, .{ x + width, y }, .{ x + width, y + height }, .{ x, y + height } };
}

// Loads appropiate settings for shapes
pub fn load_shapes() void {
    c.GX_InvVtxCache();
    c.GX_ClearVtxDesc();

    // c.GX_SetVtxDesc(c.GX_VA_TEX0, c.GX_NONE);
    c.GX_SetVtxDesc(c.GX_VA_POS, c.GX_DIRECT);
    c.GX_SetVtxDesc(c.GX_VA_CLR0, c.GX_DIRECT);

    // setup the vertex attribute table
    // describes the data
    // args: vat location 0-7, type of data, data format, size, scale
    // so for ex. in the first call we are sending position data with
    // 3 values X,Y,Z of size F32. scale sets the number of fractional
    // bits for non float data.
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_POS, c.GX_POS_XY, c.GX_F32, 0);
    c.GX_SetVtxAttrFmt(c.GX_VTXFMT0, c.GX_VA_CLR0, c.GX_CLR_RGBA, c.GX_RGB8, 0);

    c.GX_SetNumChans(1);
    c.GX_SetNumTexGens(0);
    c.GX_SetTevOrder(c.GX_TEVSTAGE0, c.GX_TEXCOORDNULL, c.GX_TEXMAP_NULL, c.GX_COLOR0A0);
    c.GX_SetTevOp(c.GX_TEVSTAGE0, c.GX_PASSCLR);
}
