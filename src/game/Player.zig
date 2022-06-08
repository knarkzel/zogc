const Player = @This();
const std = @import("std");
const Pad = @import("../ogc/Pad.zig");
const game = @import("game.zig");
const components = @import("components.zig");
const utils = @import("../utils.zig");

const jumps_max: u8 = 2;
const dashes_max: u8 = 1;
const attack_time: u8 = 20;

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

pub fn init(x: f32, y: f32, port: usize) Player {
    return .{ .x = x, .y = y, .port = port };
}

const State = union(enum) {
    regular,
    dash: struct {
        time_left: u8 = 10,
        delta_x: f32,
        delta_y: f32,
    },
    attack: struct {
        time_left: u8,
    },
};

pub fn setState(self: *Player, state: State) void {
    self.*.state = state;
}

const Direction = enum { left, right };

pub fn drawSprite(self: *Player, comptime sprite: game.Sprite) void {
    var area = utils.rectangle(self.x, self.y, self.width, self.height);
    if (self.direction == .left) utils.mirror(&area);
    sprite.draw(area);
}

fn sword_area(self: *Player) [4][2]f32 {
    const offset: [2]f32 = if (self.*.direction == .left) .{ -3, 90 } else .{ -29, 90 };
    return utils.rectangle(self.*.x - offset[0], self.*.y - offset[1], 32, 96);
}

pub fn run(self: *Player, state: *game.State) void {
    // Exit
    if (Pad.button_down(.start, self.port)) std.os.exit(0);

    // Bounds
    if (self.*.x > 640) self.*.x = -64;
    if (self.*.x + 64 < 0) self.*.x = 640;
    const speed: f32 = 10;

    // States
    switch (self.*.state) {
        .regular => {
            // Movement
            const deadzone = 0.1;
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

            // Dash
            if (Pad.button_down(.x, self.port) and self.dashes > 0) {
                self.*.y_speed = 0;
                self.dashes -= 1;
                self.*.state = .{ .dash = .{ .delta_x = stick_x, .delta_y = stick_y } };
            }

            // Attack
            if (Pad.button_down(.a, self.port)) self.*.state = .{ .attack = .{ .time_left = attack_time } };

            // Draw regular sword
            if (self.*.grounded) {
                var area = self.sword_area();
                if (self.*.direction == .right) utils.mirror(&area);
                game.Sprite.player_sword.draw(area);
            }

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
            var angle: f32 = 90 - 90 * (@intToFloat(f32, attack.*.time_left) / @intToFloat(f32, attack_time));
            if (self.*.direction == .left) angle = -angle;
            var area = self.sword_area();
            const x = area[0][0];
            const y = area[0][1];
            const width = area[1][0] - area[0][0];
            const height = area[2][1] - area[0][1];

            // Draw attacking sword
            if (self.*.direction == .right) utils.mirror(&area);
            utils.rotate_point(&area, .{ x + width / 2, y + height }, angle);
            game.Sprite.player_sword.draw(area);

            // Draw attacking player
            self.drawSprite(.player_fall);

            // Handle state
            attack.*.time_left -= 1;
            if (attack.*.time_left == 0) self.*.state = .regular;
        },
    }

    // Physics component
    components.add_physics(self, state);
    if (self.state == .regular and self.grounded) {
        self.*.jumps = jumps_max;
        self.*.dashes = dashes_max;
    }

    // Draw health
    var hp = self.*.health;
    while (hp > 0) : (hp -= 1) {
        var offset_x = (self.*.x - 48) + (hp * 32);
        var area = utils.rectangle(offset_x, self.y - 32, 32, 32);
        game.Sprite.heart.draw(area);
    }
}
