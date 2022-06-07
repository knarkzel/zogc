const Slime = @This();
const game = @import("game.zig");
const utils = @import("../utils.zig");

x: f32,
y: f32,
width: f32 = 64,
height: f32 = 64,
velocity: f32 = 0,
direction: Direction = .right,

pub fn init(x: f32, y: f32) Slime {
    return .{ .x = x, .y = y };
}

const Direction = enum { left, right };

pub fn drawSprite(self: *Slime, comptime sprite: game.Sprite) void {
    var area = utils.rectangle(self.x, self.y, self.width, self.height);
    if (self.direction == .left) utils.mirror(&area);
    sprite.draw(area);
}

pub fn run(self: *Slime, _: *game.State) void {
    self.drawSprite(.slime_idle);
    if (self.y + self.height > 480) {
        self.velocity = 0;
        self.y = 480 - self.height;
    }
    if (self.velocity > -6) self.velocity -= 0.25;
    self.y -= self.velocity;
    if (self.direction == .right) self.x += 1 else self.x -= 1;
    if (self.x + self.width > 640) self.direction = .left;
    if (self.x < 0) self.direction = .right;
}
