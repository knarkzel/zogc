const c = @import("../c.zig");
const utils = @import("../utils.zig");
const Video = @import("../ogc/Video.zig");
const Gpu = @import("../ogc/Gpu.zig");
const Pad = @import("../ogc/Pad.zig");

// Objects
const Player = @import("Player.zig");
const Slime = @import("Slime.zig");
const Block = @import("Block.zig");

// Global sprites
pub const Sprite = enum {
    player_idle,
    player_dash,
    player_jump,
    player_fall,
    player_dead,
    player_attack,
    player_sword,
    slime_idle,
    slime_jump,
    slime_fall,
    grass,
    dirt,
    brick,
    brick_altered,
    block,
    heart,

    pub fn draw(comptime self: Sprite, area: [4][2]f32) void {
        const settings: [4]f32 = switch (self) {
            //                 x  y  w   h
            .player_idle => .{ 0, 0, 32, 32 },
            .player_dash => .{ 32, 0, 32, 32 },
            .player_jump => .{ 0, 32, 32, 32 },
            .player_fall => .{ 32, 32, 32, 32 },
            .player_dead => .{ 32, 64, 32, 32 },
            .player_attack => .{ 32, 64, 32, 32 },
            .player_sword => .{ 64, 0, 32, 96 },
            .slime_idle => .{ 96, 0, 32, 32 },
            .slime_jump => .{ 128, 0, 32, 32 },
            .slime_fall => .{ 96, 32, 32, 32 },
            .grass => .{ 160, 96, 32, 32 },
            .dirt => .{ 192, 96, 32, 32 },
            .brick => .{ 0, 160, 32, 32 },
            .brick_altered => .{ 32, 160, 32, 32 },
            .block => .{ 64, 160, 32, 32 },
            .heart => .{ 128, 96, 32, 32 },
        };
        utils.sprite(area, settings, .{ 256, 256 });
    }
};

// Global state
pub const State = struct {
    players: [4]?Player = .{null} ** 4,
    blocks: [screen_width / 32 + 2]Block = undefined,
    slime: Slime,
};

// Constants
const screen_width = 640;
const screen_height = 480;

pub fn run(video: *Video) void {
    // Texture
    var texture = Gpu.init();
    texture.load_tpl("textures/atlas.tpl");

    // State
    var state = State{
        .slime = Slime.init(200, 200),
    };
    for (state.blocks) |*block, i| block.* = Block.init(-32 + (@intToFloat(f32, i) * 32), screen_height - 32);

    while (true) {
        // Handle new players
        for (Pad.update()) |controller, i| {
            if (controller and state.players[i] == null) state.players[i] = Player.init(128, 32, i);
        }

        video.start();

        for (state.players) |*object| if (object.*) |*player| player.run(&state);
        for (state.blocks) |*block| block.drawSprite(.block);
        state.slime.run(&state);

        video.finish();
    }
}
