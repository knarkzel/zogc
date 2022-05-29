const c = @import("c.zig");
const utils = @import("utils.zig");

const Audio = @This();
voices: [16]bool,

pub fn init() Audio {
    c.ASND_Init();
    return .{ .voices = .{false} ** 16 };
}

const Mode = enum { one_time, infinite_time };

// Takes pointer to ogg and plays it
pub fn load_ogg(self: *Audio, comptime path: []const u8, mode: Mode) void {
    for (self.voices) |*voice| {
        if (!voice.*) {
            voice.* = true;
            const ogg = @embedFile(path);
            _ = c.PlayOgg(ogg, ogg.len, 0, @enumToInt(mode));
        }
    }
}
