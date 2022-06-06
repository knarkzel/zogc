const c = @import("../c.zig");
const utils = @import("../utils.zig");
const Video = @import("../ogc/Video.zig");
const Gpu = @import("../ogc/Gpu.zig");
const Pad = @import("../ogc/Pad.zig");

// Sprites
const Sprite = enum {
    idle,
    dash,
    jump,
    fall,
    sword,

    fn draw(comptime self: Sprite, area: [4][2]f32) void {
        const settings: [4]f32 = switch (self) {
            //          x  y  w   h
            .idle => .{ 0, 0, 32, 32 },
            .dash => .{ 32, 0, 32, 32 },
            .jump => .{ 0, 32, 32, 32 },
            .fall => .{ 32, 32, 32, 32 },
            .sword => .{ 64, 0, 32, 96 },
        };
        // Current texture atlas size (textures.png)
        const size = .{ 96, 96 };
        utils.sprite(area, settings, size);
    }
};

// Player
const Player = struct {
    x: f32,
    y: f32,
    velocity: f32,
    state: State,
    direction: Direction,

    fn init(x: f32, y: f32) Player {
        return Player{ .x = x, .y = y, .velocity = 0, .state = .regular, .direction = .right };
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
        var area = utils.rectangle(self.x, self.y, 64, 64);
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
                    player.*.y = 480 - 64;
                }

                // States
                switch (player.*.state) {
                    .regular => {
                        // Sprites
                        if (player.*.velocity < 0) {
                            player.drawSprite(.fall);
                        } else if (player.*.velocity > 0) {
                            player.drawSprite(.jump);
                        } else player.drawSprite(.idle);

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
                        player.drawSprite(.dash);

                        // Sword
                        var area = utils.rectangle(player.*.x + 32, player.*.y, 32, 96);
                        Sprite.sword.draw(area);

                        // Movement
                        player.*.x += speed * dash.delta_x * 1.5;
                        player.*.y += speed * dash.delta_y * 1.5;
                        dash.*.time_left -= 1;
                        if (dash.*.time_left == 0) player.setState(.regular);
                    },
                }
            }
        }

        video.finish();
    }
}
