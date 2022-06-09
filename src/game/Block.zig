const Block = @This();
const Sprite = @import("game.zig").Sprite;
const utils = @import("../utils.zig");

x: f32,
y: f32,
sprite: Sprite,
width: f32 = 32,
height: f32 = 32,

pub fn init(x: f32, y: f32, sprite: Sprite) Block {
    return .{ .x = x, .y = y, .sprite = sprite };
}

pub fn drawSprite(self: *Block) void {
    var area = utils.rectangle(self.x, self.y, self.width, self.height);
    self.sprite.draw(area);
}
