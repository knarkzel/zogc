const Player = @This();
const std = @import("std");
const Pad = @import("../ogc/Pad.zig");
const game = @import("game.zig");
const components = @import("components.zig");
const utils = @import("../utils.zig");

const deadzone = 0.1;
const speed: f32 = 10;
const jumps_max: u8 = 2;
const dashes_max: u8 = 1;
const attack_time: u8 = 15;

x: f32,
y: f32,
port: usize,
x_speed: f32 = 0,
y_speed: f32 = 0,
width: f32 = 64,
height: f32 = 64,
gravity: f32 = 0.25,
jumps: u8 = jumps_max,
dashes: u8 = dashes_max,
grounded: bool = false,
state: State = .regular,
direction: Direction = .right,
health: f32 = 3,

const Direction = enum { left, right };

pub fn init(x: f32, y: f32, port: usize) Player {
    return .{ .x = x, .y = y, .port = port };
}

const State = union(enum) {
    regular,
    dash: struct {
        time_left: u8,
        delta_x: f32,
        delta_y: f32,
    },
    attack: struct {
        time_left: u8,
    },
    hurt: struct {
        time_left: u8,
        delta_x: f32,
    },
};

pub fn setState(self: *Player, state: State) void {
    self.*.state = state;
}

pub fn drawSprite(self: *Player, comptime sprite: game.Sprite) void {
    sprite.draw(self.area());
}

pub fn area(self: *Player) [4][2]f32 {
    var box = utils.rectangle(self.x, self.y, self.width, self.height);
    if (self.direction == .left) utils.mirror(&box);
    if (self.state == .attack) utils.rotate(&box, utils.center(box), self.sword_angle().?);
    return box;
}

fn sword_angle(self: *Player) ?f32 {
    if (self.state != .attack) return null;
    var angle: f32 = 360 - 360 * (@intToFloat(f32, self.state.attack.time_left) / @intToFloat(f32, attack_time));
    if (self.direction == .left) angle = -angle;
    return angle;
}

pub fn sword_area(self: *Player) ?[4][2]f32 {
    if (self.state != .attack) return null;
    const offset: [2]f32 = if (self.direction == .left) .{ 2, 60 } else .{ -34, 60 };
    const angle = self.sword_angle().?;
    var box = utils.rectangle(self.*.x - offset[0], self.*.y - offset[1], 32, 96);
    const x = box[0][0];
    const y = box[0][1];
    const width = box[1][0] - box[0][0];
    const height = box[2][1] - box[0][1];

    // Draw attacking sword
    if (self.direction == .right) {
        utils.mirror(&box);
        utils.rotate(&box, .{ x + width / 2, y + height }, 90);
    } else utils.rotate(&box, .{ x + width / 2, y + height }, -90);
    utils.rotate(&box, .{ self.x + self.width / 2, self.y + self.height / 2 }, angle);
    return box;
}

pub fn drawHealth(self: *Player) void {
    var hp = self.*.health;
    while (hp > 0) : (hp -= 1) {
        var offset_x = (self.*.x - 16) + (hp * 16);
        game.Sprite.heart.draw(utils.rectangle(offset_x, self.y - 32, 32, 32));
    }
}

pub fn run(self: *Player, state: *game.State) void {
    // Exit
    if (Pad.button_down(.start, self.port)) std.os.exit(0);

    // States
    switch (self.*.state) {
        .regular => {
            self.drawHealth();

            // Movement
            const stick_x = Pad.stick_x(self.port);
            const stick_y = Pad.stick_y(self.port);
            if (stick_x > deadzone or stick_x < -deadzone) {
                self.*.x_speed = stick_x * speed;
                self.*.direction = if (stick_x > 0) .right else .left;
            } else self.*.x_speed = 0;

            // Jumping
            self.*.gravity = if (Pad.button_held(.y, self.port) and self.*.y_speed < 0) 0.01 else 0.25;
            if (Pad.button_down(.y, self.port) and self.jumps > 0) {
                self.*.y_speed = speed;
                self.jumps -= 1;
            }

            // Draw glider
            if (self.*.gravity == 0.01) {
                game.Sprite.glider.draw(utils.rectangle(self.x, self.y - 64, 64, 64));
            }

            // Dash
            if (Pad.button_down(.x, self.port) and self.dashes > 0) {
                self.*.y_speed = 0;
                self.dashes -= 1;
                self.*.state = .{ .dash = .{ .time_left = 10, .delta_x = stick_x, .delta_y = stick_y } };
            }

            // Attack
            if (Pad.button_down(.a, self.port)) self.*.state = .{ .attack = .{ .time_left = attack_time } };

            // Sprites
            if (self.*.y_speed < 0) {
                self.drawSprite(.player_fall);
            } else if (self.*.y_speed > 0) {
                self.drawSprite(.player_jump);
            } else self.drawSprite(.player_idle);
        },
        .dash => |*dash| {
            // Movement
            self.*.x_speed = speed * dash.delta_x * 1.5;
            self.*.y_speed = speed * dash.delta_y * 1.5;
            dash.*.time_left -= 1;
            if (dash.*.time_left == 0) {
                self.*.x_speed = 0;
                self.*.y_speed = 0;
                self.*.state = .regular;
            }

            // Sprites
            self.drawSprite(.player_dash);
        },
        .attack => |*attack| {
            // Draw spinning sword
            game.Sprite.player_sword.draw(self.sword_area().?);

            // Draw attacking player
            self.drawSprite(.player_attack);

            // Handle state
            attack.*.time_left -= 1;
            if (attack.*.time_left == 0) self.*.state = .regular;
        },
        .hurt => |*hurt| {
            // Movement
            self.*.x_speed = hurt.delta_x;

            // Draw hurt player
            self.drawSprite(.player_hurt);

            // Handle state
            hurt.*.time_left -= 1;
            if (hurt.time_left == 0) {
                if (self.health == 0) {
                    self.*.state = .regular;
                    self.* = Player.init(128, 32, self.port);
                    return;
                }
                self.*.state = .regular;
            }
        },
    }

    // Hurtbox component
    if (self.state != .hurt) {
        if (utils.offset_collides(self.area(), state.slime.area())) |delta| {
            const knockback = 5;
            self.*.health -= 1;
            self.*.y_speed = delta[1] * knockback;
            self.*.state = .{ .hurt = .{ .time_left = 30, .delta_x = -delta[0] * knockback } };
        }
    }

    // Physics component
    components.add_physics(self, state);
    if (self.state == .regular and self.grounded) {
        self.*.jumps = jumps_max;
        self.*.dashes = dashes_max;
    }
}
