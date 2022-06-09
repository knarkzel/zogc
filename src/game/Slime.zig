const Slime = @This();
const std = @import("std");
const game = @import("game.zig");
const utils = @import("../utils.zig");
const components = @import("components.zig");
const Rng = std.rand.DefaultPrng;

x: f32,
y: f32,
state: State,
rng: std.rand.Xoshiro256,
width: f32 = 64,
height: f32 = 64,
x_speed: f32 = 0,
y_speed: f32 = 0,
gravity: f32 = 0.25,
direction: Direction = .right,
health: f32 = 5,
isDead: bool = false,

const Direction = enum { left, right };

const State = union(enum) {
    regular: struct { time_left: u8 },
    charging: struct { time_left: u8 },
    hurt: struct {
        time_left: u8,
        velocity_x: f32,
    },
};

pub fn init(x: f32, y: f32) Slime {
    return .{ .x = x, .y = y, .state = .{ .regular = .{ .time_left = 60 } }, .rng = Rng.init(0) };
}

pub fn drawSprite(self: *Slime, comptime sprite: game.Sprite) void {
    sprite.draw(self.area());
}

pub fn drawHealth(self: *Slime) void {
    var hp = self.*.health;
    while (hp > 0) : (hp -= 1) {
        var offset_x = (self.*.x - 32) + (hp * 16);
        game.Sprite.heart.draw(utils.rectangle(offset_x, self.y - 32, 32, 32));
    }
}

pub fn area(self: *Slime) [4][2]f32 {
    var box = utils.rectangle(self.x, self.y, self.width, self.height);
    if (self.direction == .left) utils.mirror(&box);
    return box;
}

pub fn run(self: *Slime, state: *game.State) void {

    // Death check
    if (self.health <= 0) self.*.isDead = true;

    // Components
    components.add_physics(self, state);

    // Horizontal velocity
    if (@fabs(self.x_speed) > 0) self.*.x_speed /= 1.1;

    // Movement
    switch (self.*.state) {
        .regular => |*regular| {
            regular.*.time_left -= 1;
            if (regular.time_left == 0) {
                if (self.rng.random().boolean()) {
                    self.*.x_speed = 0;
                    self.*.state = .{ .charging = .{ .time_left = 30 } };
                } else {
                    self.*.x_speed = @intToFloat(f32, self.rng.random().intRangeAtMost(i8, -1, 1));
                    regular.*.time_left = self.rng.random().intRangeAtMost(u8, 30, 240);
                }
            }

            // Sprites
            if (self.y_speed != 0) self.drawSprite(.slime_jump) else self.drawSprite(.slime_idle);

            self.drawHealth();
        },
        .charging => |*charging| {
            // Handle charging
            charging.*.time_left -= 1;
            if (charging.time_left == 0) {
                self.*.x_speed = @intToFloat(f32, self.rng.random().intRangeAtMost(i32, -3, 3));
                self.*.y_speed = @intToFloat(f32, self.rng.random().intRangeAtMost(i32, 5, 10));
                self.*.state = .{ .regular = .{ .time_left = 60 } };
            }

            // Sprites
            self.drawSprite(.slime_fall);
        },
        .hurt => |*hurt| {
            // Movement
            hurt.*.velocity_x /= 1.5;
            self.*.x_speed += hurt.velocity_x;

            // Draw hurt slime
            self.drawSprite(.slime_hurt);

            // Handle state
            hurt.*.time_left -= 1;
            if (hurt.time_left == 0) self.*.state = .{ .regular = .{ .time_left = 120 } };
        },
    }

    // Get hurt by player
    if (self.state != .hurt) {
        for (state.players) |*object| {
            if (object.*) |*player| {
                if (player.sword_area()) |sword| {
                    if (utils.diag_collides(self.area(), sword)) |delta| {
                        const knockback = 8;
                        const diff = self.x - player.x;
                        const sign: f32 = if ((diff > 0) == (delta[0] > 0) or (diff < 0) == (delta[0] < 0)) -1 else 1;
                        self.*.y_speed = delta[1] * knockback;
                        self.*.state = .{ .hurt = .{ .time_left = 30, .velocity_x = -delta[0] * knockback * sign } };
                        self.*.health -= 1;
                        break;
                    }
                }
            }
        }
    }

    // Direction
    if (self.x_speed < 0) self.*.direction = .left;
    if (self.x_speed > 0) self.*.direction = .right;
}
