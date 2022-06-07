const c = @import("../c.zig");
const utils = @import("../utils.zig");
const Video = @import("../ogc/Video.zig");
const Gpu = @import("../ogc/Gpu.zig");
const Pad = @import("../ogc/Pad.zig");

// Sprites
const Sprite = enum {
    player_idle,
    player_dash,
    player_jump,
    player_fall,
    player_sword,
    slime_idle,

    fn draw(comptime self: Sprite, area: [4][2]f32) void {
        const settings: [4]f32 = switch (self) {
            //                 x  y  w   h
            .player_idle => .{ 0, 0, 32, 32 },
            .player_dash => .{ 32, 0, 32, 32 },
            .player_jump => .{ 0, 32, 32, 32 },
            .player_fall => .{ 32, 32, 32, 32 },
            .player_sword => .{ 64, 0, 32, 96 },
            .slime_idle => .{ 128, 0, 32, 32 },
        };
        // Current texture atlas size (textures.png)
        const size = .{ 256, 256 };
        utils.sprite(area, settings, size);
    }
};

// Player
const Player = struct {
    x: f32,
    y: f32,
    width: f32 = 64,
    height: f32 = 64,
    velocity: f32 = 0,
    angle: f32 = 0,
    grounded: bool = false,
    state: State = .regular,
    direction: Direction = .right,

    fn init(x: f32, y: f32) Player {
        return .{ .x = x, .y = y };
    }

    const State = union(enum) {
        regular,
        dash: struct {
            time_left: u32,
            delta_x: f32,
            delta_y: f32,
        },
    };

    fn setState(self: *Player, state: State) void {
        self.*.state = state;
    }

    const Direction = enum { left, right };

    fn drawSprite(self: *Player, comptime sprite: Sprite) void {
        var area = utils.rectangle(self.x, self.y, self.width, self.height);
        if (self.direction == .left) utils.mirror(&area);
        self.angle += 1;
        if (self.angle > 360) self.angle = 0;
        utils.rotate(&area, self.angle);
        sprite.draw(area);
    }
};

const Slime = struct {
    x: f32,
    y: f32,
    width: f32 = 64,
    height: f32 = 64,
    velocity: f32 = 0,
    direction: Direction = .right,

    fn init(x: f32, y: f32) Slime {
        return .{ .x = x, .y = y };
    }

    const Direction = enum { left, right };

    fn drawSprite(self: *Slime, comptime sprite: Sprite) void {
        var area = utils.rectangle(self.x, self.y, self.width, self.height);
        if (self.direction == .left) utils.mirror(&area);
        sprite.draw(area);
    }
};

pub fn run(video: *Video) void {
    // Texture
    var texture = Gpu.init();
    texture.load_tpl("textures/atlas.tpl");

    // Players
    var players: [4]?Player = .{null} ** 4;

    // Slime
    var slime = Slime.init(200, 200);

    while (true) {
        // Handle new players
        for (Pad.update()) |controller, i| {
            if (controller and players[i] == null) players[i] = Player.init(128, 32);
        }

        video.start();

        // Players logic
        for (players) |*object, i| {
            if (object.*) |*player| {
                // Exit
                if (Pad.button_down(.start, i)) return;

                // Bounds
                if (player.*.x > 640) player.*.x = -64;
                if (player.*.x + 64 < 0) player.*.x = 640;
                const speed: f32 = if (Pad.button_held(.b, i)) 15 else 10;
                if (player.*.y + 64 > 480) {
                    player.*.velocity = 0;
                    player.*.grounded = true;
                    player.*.y = 480 - 64;
                } else player.*.grounded = false;

                // States
                switch (player.*.state) {
                    .regular => {
                        // Sprites
                        if (player.*.velocity < 0) {
                            player.drawSprite(.player_fall);
                        } else if (player.*.velocity > 0) {
                            player.drawSprite(.player_jump);
                        } else {
                            if (player.*.grounded) {
                                // Draw sword properly
                                const offset_x: f32 = if (player.*.direction == .left) -32 else 0;
                                var area = utils.rectangle(player.*.x - offset_x, player.*.y - 74, 32, 96);
                                if (player.*.direction == .right) utils.mirror(&area);
                                Sprite.player_sword.draw(area);
                            }
                            player.drawSprite(.player_idle);
                        }

                        // Movement
                        const deadzone = 0.1;
                        const stick_x = Pad.stick_x(i);
                        const stick_y = Pad.stick_y(i);
                        if (stick_x > deadzone or stick_x < -deadzone) {
                            player.*.x += stick_x * speed;
                            player.*.direction = if (stick_x > 0) .right else .left;
                        }

                        // Jumping
                        const gravity: f32 = if (Pad.button_held(.a, i) and player.*.velocity < 0) 0.05 else 0.25;
                        if (player.*.velocity > -6) player.*.velocity -= gravity;
                        if (Pad.button_down(.a, i)) {
                            player.*.velocity = speed;
                        }
                        player.*.y -= player.*.velocity;

                        // Dash
                        if (Pad.button_down(.y, i)) {
                            player.*.velocity = 0;
                            player.setState(.{ .dash = .{ .time_left = 10, .delta_x = stick_x, .delta_y = -stick_y } });
                        }
                    },
                    .dash => |*dash| {
                        // Sprites
                        player.drawSprite(.player_dash);

                        // Movement
                        player.*.x += speed * dash.delta_x * 1.5;
                        player.*.y += speed * dash.delta_y * 1.5;
                        dash.*.time_left -= 1;
                        if (dash.*.time_left == 0) player.setState(.regular);
                    },
                }
            }
        }

        // Slime logic
        slime.drawSprite(.slime_idle);
        if (slime.y + slime.height > 480) {
            slime.velocity = 0;
            slime.y = 480 - slime.height;
        }
        if (slime.velocity > -6) slime.velocity -= 0.25;
        slime.y -= slime.velocity;
        if (slime.direction == .right) slime.x += 1 else slime.x -= 1;
        if (slime.x + slime.width > 640) slime.direction = .left;
        if (slime.x < 0) slime.direction = .right;

        video.finish();
    }
}
