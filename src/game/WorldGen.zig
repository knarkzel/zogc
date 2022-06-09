const std = @import("std");
const ArrayList = std.ArrayList;
const Block = @import("Block.zig");
const game = @import("game.zig");

pub fn generate(blocks: *ArrayList(Block)) !void {
    try base_platforms(blocks);
}

fn base_platforms(blocks: *ArrayList(Block)) !void {
    var block: f32 = 0;
    while (block < game.screen_width / 32 * 3) : (block += 1) {
        try blocks.append(Block.init(-game.screen_width + block * 32, game.screen_height - 32));
    }
}
