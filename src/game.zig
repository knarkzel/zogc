const c = @import("ogc/c.zig");
const Video = @import("ogc/Video.zig");
const Texture = @import("ogc/Texture.zig");
const pad = @import("ogc/pad.zig");
const utils = @import("ogc/utils.zig");

const Player = struct {
    // zig fmt: off
    const State = union(enum) {
        regular,
        dash: struct {
            time_left: u32,
            direction: f32,
        }
    };
    
    x: f32,
    y: f32,
    velocity: f32,
    state: State,

    fn init(x: f32, y: f32) Player {
        return Player{ .x = x, .y = y, .velocity = 0, .state = .regular };
    }

    fn setState(self: *Player, state: State) void {
        self.*.state = state;
    }
};

pub fn run(video: *Video) void {
    // Players
    var players: [4]?Player = .{ null, null, null, null };


    while (true) {
        // Handle new players
        for (pad.update()) |controller, i| {
            if (controller and players[i] == null) players[i] = Player.init(128, 32);
        }

        video.start();

        // Players logic
        const colors = [4]utils.Rectangle{
            utils.rectangle(0, 0, 0.5, 0.5),
            utils.rectangle(0, 0.5, 0.5, 0.5),
            utils.rectangle(0.5, 0, 0.5, 0.5),
            utils.rectangle(0.5, 0.5, 0.5, 0.5),
        };

        for (players) |*object, i| {
            if (object.*) |*player| {
                // Exit
                if (pad.button_down(.start, i)) return;

                // Bounds
                if (player.*.x > 640) player.*.x = -64;
                if (player.*.x + 64 < 0) player.*.x = 640;
                const speed: f32 = if (pad.button_held(.b, i)) 15 else 10;
                
                // States
                switch (player.*.state) {
                    .regular => {
                        // Movement
                        const stick_x = pad.stick_x(i);
                        player.*.x += stick_x * speed;

                        // Jumping
                        if (player.*.y + 64 > 480) player.*.velocity = 0;
                        if (pad.button_down(.a, i)) {
                            const jump = @embedFile("jump.mp3");
                            c.MP3Player_Stop();
                            _ = c.MP3Player_PlayBuffer(jump, jump.len, null);
                            player.*.velocity = speed;
                        }
                        player.*.y -= player.*.velocity;
                        if (player.*.velocity > -6) player.*.velocity -= 0.25;

                        // Dash
                        if (pad.button_down(.y, i)) {
                            const dash = @embedFile("dash.mp3");
                            c.MP3Player_Stop();
                            _ = c.MP3Player_PlayBuffer(dash, dash.len, null);
                            player.*.velocity = 0;
                            const direction: f32 = if (stick_x > 0) 1 else -1;
                            player.setState(.{ .dash = .{ .time_left = 10, .direction = direction } });
                        }
                    },
                    .dash => |*dash| {
                        player.*.x += speed * dash.*.direction * 1.5;
                        dash.*.time_left -= 1;
                        if (dash.*.time_left == 0) player.setState(.regular);
                    },
                }

                // Graphics
                const points = utils.rectangle(player.x, player.y, 64, 64);
                const coords = colors[i];
                utils.texture(points, coords);
            }
        }

        video.finish();
    }
}
