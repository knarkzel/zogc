const Block = @This();
const Sprite = @import("game.zig").Sprite;
const utils = @import("../utils.zig");

x: f32,
y: f32,
width: f32 = 32,
height: f32 = 32,

pub fn init(x: f32, y: f32) Block {
    return .{ .x = x, .y = y };
}

pub fn drawSprite(self: *Block, comptime sprite: Sprite) void {
    var area = utils.rectangle(self.x, self.y, self.width, self.height);
    sprite.draw(area);
}
