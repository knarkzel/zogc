const c = @import("../ogc/c.zig");
const Video = @import("../ogc/Video.zig");
const Texture = @import("../ogc/Texture.zig");
const Pad = @import("../ogc/Pad.zig");
const utils = @import("../ogc/utils.zig");

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
            direction: f32,
        },
    };

    fn setState(self: *Player, state: State) void {
        self.*.state = state;
    }

    const Direction = enum {
        left, right  
    };
    
    const Sprite = enum {
        idle,
        dash,
        jump,
        fall,
    };

    fn drawSprite(self: *Player, comptime sprite: Sprite) void {
        var area = utils.rectangle(self.x, self.y, 64, 64);
        if (self.direction == .left) utils.mirror(&area);
        const coord: [2]f32 = switch (sprite) {
            .idle => .{ 0, 0 },
            .dash => .{ 1, 0 },
            .jump => .{ 0, 1 },
            .fall => .{ 1, 1 },
        };
        utils.sprite(area, coord, 64, 64);
    }
};

pub fn run(video: *Video) void {
    // Texture
    var texture = Texture.init();
    texture.load_tpl("textures/textures.tpl");

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
                        const stick_x = Pad.stick_x(i);
                        if (stick_x > Pad.deadzone or stick_x < -Pad.deadzone) player.*.x += stick_x * speed;

                        player.*.direction = if (stick_x > 0) .right else .left;

                        // Jumping
                        if (player.*.velocity > -6) player.*.velocity -= 0.25;
                        if (player.*.y + 64 > 480) player.*.velocity = 0;
                        if (Pad.button_down(.a, i)) {
                            const jump = @embedFile("audio/jump.mp3");
                            c.MP3Player_Stop();
                            _ = c.MP3Player_PlayBuffer(jump, jump.len, null);
                            player.*.velocity = speed;
                        }
                        player.*.y -= player.*.velocity;

                        // Dash
                        if (Pad.button_down(.y, i)) {
                            const dash = @embedFile("audio/dash.mp3");
                            c.MP3Player_Stop();
                            _ = c.MP3Player_PlayBuffer(dash, dash.len, null);
                            player.*.velocity = 0;
                            const direction: f32 = if (stick_x > 0) 1 else -1;
                            player.setState(.{ .dash = .{ .time_left = 10, .direction = direction } });
                        }
                    },
                    .dash => |*dash| {
                        // Sprites
                        player.drawSprite(.dash);

                        // Movement
                        player.*.x += speed * dash.*.direction * 1.5;
                        dash.*.time_left -= 1;
                        if (dash.*.time_left == 0) player.setState(.regular);
                    },
                }
            }
        }

        video.finish();
    }
}
