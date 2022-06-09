const Camera = @This();
const game = @import("game.zig");

x: f32,
y: f32,
smoothing: f32 = 20,

pub fn init() Camera {
    return .{ .x = 0, .y = 0 };
}

pub fn follow(self: *Camera, x: f32, y: f32) void {
    self.x += (x - (self.x + (game.screen_width - 64) / 2)) / self.smoothing;
    self.y += (y - (self.y + (game.screen_height - 64) / 2)) / self.smoothing;
    if (self.x < -game.screen_width) self.*.x = -game.screen_width;
    if (self.x > game.screen_width) self.*.x = game.screen_width;
    if (self.y > 0) self.*.y = 0;
}
