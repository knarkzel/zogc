const WorldGen = @This();
const std = @import("std");
const ArrayList = std.ArrayList;
const Block = @import("Block.zig");
const game = @import("game.zig");
const Rng = std.rand.DefaultPrng;

rng: std.rand.Xoshiro256,

pub fn init() WorldGen {
    return .{ .rng = Rng.init(0) };
}

pub fn generate(self: *WorldGen, state: *game.State) !void {
    try self.base_grass(&state.blocks);
}

fn base_grass(self: *WorldGen, blocks: *ArrayList(Block)) !void {

    var height: f32 = 3; 

    const start: usize = 4;
    const end: usize = 88; 
    const smoothen: usize = 3; 

    var i: f32 = 0;
    var count: usize = 0;
    while (i < game.screen_width / 32 * 3) : (i += 1) {
        if (count < smoothen) count += 1; 

        if (count == smoothen) {
            const chance = self.rng.random().intRangeAtMost(u8, 0, 10);
            if (chance > 8 and height < end) {
                height += 1; 
                count = 0; 
            }
            if (chance < 2 and height > start) {
                height -= 1; 
                count = 0; 
            }
        }

        var j: f32 = height - 1; 
        while (j > 0) :(j -= 1) {
            try blocks.append(Block.init(-game.screen_width + i * 32, game.screen_height - (j * 32), .dirt));
        }

        try blocks.append(Block.init(-game.screen_width + i * 32, game.screen_height - (height * 32), .grass));
    }
}
