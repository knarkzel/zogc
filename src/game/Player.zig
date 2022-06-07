const Player = @This();
const std = @import("std");
const Pad = @import("../ogc/Pad.zig");
const game = @import("game.zig");
const utils = @import("../utils.zig");

x: f32,
y: f32,
x_speed: f32 = 0,
y_speed: f32 = 0,
port: usize,
width: f32 = 64,
height: f32 = 64,
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
        time_left: u32,
        delta_x: f32,
        delta_y: f32,
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

pub fn run(self: *Player, state: *game.State) void {
    // Exit
    if (Pad.button_down(.start, self.port)) std.os.exit(0);

    // Bounds
    if (self.*.x > 640) self.*.x = -64;
    if (self.*.x + 64 < 0) self.*.x = 640;
    const speed: f32 = if (Pad.button_held(.b, self.port)) 15 else 10;

    // States
    switch (self.*.state) {
        .regular => {
            // Sprites
            if (self.*.y_speed < 0) {
                self.drawSprite(.player_fall);
            } else if (self.*.y_speed > 0) {
                self.drawSprite(.player_jump);
            } else self.drawSprite(.player_idle);

            // Movement
            const deadzone = 0.1;
            const stick_x = Pad.stick_x(self.port);
            const stick_y = Pad.stick_y(self.port);
            if (stick_x > deadzone or stick_x < -deadzone) {
                self.*.x_speed = stick_x * speed;
                self.*.direction = if (stick_x > 0) .right else .left;
            } else self.*.x_speed = 0;

            // Jumping
            const gravity: f32 = if (Pad.button_held(.a, self.port) and self.*.y_speed < 0) 0.01 else 0.25;
            if (self.*.y_speed > -6) self.*.y_speed -= gravity;
            if (Pad.button_down(.a, self.port)) self.*.y_speed = speed;

            // Dash
            if (Pad.button_down(.y, self.port)) {
                self.*.y_speed = 0;
                self.setState(.{ .dash = .{ .time_left = 10, .delta_x = stick_x, .delta_y = stick_y } });
            }
        },
        .dash => |*dash| {
            // Sprites
            self.drawSprite(.player_dash);

            // Movement
            self.*.x_speed = speed * dash.delta_x * 1.5;
            self.*.y_speed = speed * dash.delta_y * 1.5;
            dash.*.time_left -= 1;
            if (dash.*.time_left == 0) {
                self.*.x_speed = 0;
                self.*.y_speed = 0;
                self.setState(.regular);
            }
        },
    }

    // Collision
    self.*.grounded = false;
    for (state.blocks) |block| {
        const block_area = utils.rectangle(block.x, block.y, block.width, block.height);

        // Horizontal
        if (utils.collides(block_area, utils.rectangle(self.x + self.x_speed, self.y, self.width, self.height))) {
            if (self.x_speed < 0) self.*.x = block.x + block.width else self.*.x = block.x - self.width;
            self.*.x_speed = 0;
        }

        // Vertical
        if (utils.collides(block_area, utils.rectangle(self.x, self.y - self.y_speed, self.width, self.height))) {
            if (self.y_speed < 0) {
                if (self.state == .regular) self.*.grounded = true;
                self.*.y = block.y - self.height;
            } else self.*.y = block.y + block.height;
            self.*.y_speed = 0;
        }
    }

    // Draw sword
    if (self.*.grounded) {
        const offset_x: f32 = if (self.*.direction == .left) -32 else 0;
        var area = utils.rectangle(self.*.x - offset_x, self.*.y - 74, 32, 96);
        if (self.*.direction == .right) utils.mirror(&area);
        game.Sprite.player_sword.draw(area);
    }

    // Draw health
    var hp: f32 = self.*.health;

    while (hp > 0): (hp -= 1) {
        var offset_x: f32 = (self.*.x - 48) + (hp * 32);
        var area = utils.rectangle(offset_x, self.y - 32, 32, 32);
        game.Sprite.heart.draw(area);
    }

    // Apply speed
    self.*.x += self.*.x_speed;
    self.*.y -= self.*.y_speed;
}
