const Slime = @This();
const game = @import("game.zig");
const utils = @import("../utils.zig");
const components = @import("components.zig");

x: f32,
y: f32,
width: f32 = 64,
height: f32 = 64,
x_speed: f32 = 0,
y_speed: f32 = 0,
gravity: f32 = 0.25,

pub fn init(x: f32, y: f32) Slime {
    return .{ .x = x, .y = y };
}

const Direction = enum { left, right };

pub fn drawSprite(self: *Slime, comptime sprite: game.Sprite) void {
    var area = utils.rectangle(self.x, self.y, self.width, self.height);
    if (self.x_speed > 0) utils.mirror(&area);
    sprite.draw(area);
}

pub fn run(self: *Slime, state: *game.State) void {
    // Components
    components.add_physics(self, state);

    // Sprites
    self.drawSprite(.slime_idle);
}
