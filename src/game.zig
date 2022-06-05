const c = @import("c.zig");
const Video = @import("Video.zig");
const Texture = @import("Texture.zig");
const pad = @import("pad.zig");
const utils = @import("utils.zig");

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
    // Music
    c.ASND_Init();
    c.MP3Player_Init();
    const sample_mp3 = @embedFile("sample.mp3");
    _ = c.MP3Player_PlayBuffer(sample_mp3, sample_mp3.len, null);

    // Input
    pad.init();

    // Texture
    var texture = Texture.init();
    texture.load_tpl("../assets/textures.tpl", 0);

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
                        if (pad.button_down(.a, i)) player.*.velocity = speed;
                        player.*.y -= player.*.velocity;
                        if (player.*.velocity > -6) player.*.velocity -= 0.25;

                        // Dash
                        if (pad.button_down(.y, i)) {
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

        if (c.MP3Player_IsPlaying() == 0) _ = c.MP3Player_PlayBuffer(sample_mp3, sample_mp3.len, null);
    }
}
