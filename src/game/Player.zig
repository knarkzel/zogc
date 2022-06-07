const Player = @This();
const Pad = @import("../ogc/Pad.zig");
const game = @import("game.zig");
const utils = @import("../utils.zig");

x: f32,
y: f32,
port: usize,
width: f32 = 64,
height: f32 = 64,
velocity: f32 = 0,
angle: f32 = 0,
grounded: bool = false,
state: State = .regular,
direction: Direction = .right,

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
    self.angle += 1;
    if (self.angle > 360) self.angle = 0;
    utils.rotate(&area, self.angle);
    sprite.draw(area);
}

pub fn run(self: *Player, state: *game.State) void {
    // Exit
    if (Pad.button_down(.start, self.port)) return;

    // Bounds
    if (self.*.x > 640) self.*.x = -64;
    if (self.*.x + 64 < 0) self.*.x = 640;
    const speed: f32 = if (Pad.button_held(.b, self.port)) 15 else 10;
    if (self.*.y + 64 > 480) {
        self.*.velocity = 0;
        self.*.grounded = true;
        self.*.y = 480 - 64;
    } else self.*.grounded = false;

    // States
    switch (self.*.state) {
        .regular => {
            // Sprites
            if (self.*.velocity < 0) {
                self.drawSprite(.player_fall);
            } else if (self.*.velocity > 0) {
                self.drawSprite(.player_jump);
            } else {
                if (self.*.grounded) {
                    // Draw sword properly
                    const offset_x: f32 = if (self.*.direction == .left) -32 else 0;
                    var area = utils.rectangle(self.*.x - offset_x, self.*.y - 74, 32, 96);
                    if (self.*.direction == .right) utils.mirror(&area);
                    game.Sprite.player_sword.draw(area);
                }
                self.drawSprite(.player_idle);
            }

            // Movement
            const deadzone = 0.1;
            const stick_x = Pad.stick_x(self.port);
            const stick_y = Pad.stick_y(self.port);
            if (stick_x > deadzone or stick_x < -deadzone) {
                self.*.x += stick_x * speed;
                self.*.direction = if (stick_x > 0) .right else .left;
            }

            // Jumping
            const gravity: f32 = if (Pad.button_held(.a, self.port) and self.*.velocity < 0) 0.05 else 0.25;
            if (self.*.velocity > -6) self.*.velocity -= gravity;
            if (Pad.button_down(.a, self.port)) {
                self.*.velocity = speed;
            }

            self.*.y -= self.*.velocity;

            // Collision check?
            for (state.blocks) |block| {
                var x1: f32 = self.x;
                var x2: f32 = block.x;
                var y1: f32 = self.y;
                var y2: f32 = block.y;
                var w1: f32 = self.width;
                var w2: f32 = block.width;
                var h1: f32 = self.height;
                var h2: f32 = block.height;

                // Colliding?
                if (x1 < x2 + w2 and
                    x1 + w1 > x2 and
                    y1 < y2 + h2 and
                    y1 + h1 > y2)
                {
                    self.*.y += self.velocity;
                    self.*.velocity = 0;
                    self.*.grounded = true;
                }
            }

            // Dash
            if (Pad.button_down(.y, self.port)) {
                self.*.velocity = 0;
                self.setState(.{ .dash = .{ .time_left = 10, .delta_x = stick_x, .delta_y = -stick_y } });
            }
        },
        .dash => |*dash| {
            // Sprites
            self.drawSprite(.player_dash);

            // Movement
            self.*.x += speed * dash.delta_x * 1.5;
            self.*.y += speed * dash.delta_y * 1.5;
            dash.*.time_left -= 1;
            if (dash.*.time_left == 0) self.setState(.regular);
        },
    }
}
