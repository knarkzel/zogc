const game = @import("game.zig");
const utils = @import("../utils.zig");

/// Adds physics handling for type. Returns whether type is grounded
/// or not. Expects following variables: x, y, width, height, x_speed, y_speed, gravity, (grounded).
/// Also modifies grounded if self has it.
pub fn add_physics(self: anytype, state: *game.State) void {
    // Gravity
    if (self.y_speed > -6) self.y_speed -= self.gravity;

    // Collision
    if (@hasField(@TypeOf(self.*), "grounded")) self.*.grounded = false;
    for (state.blocks) |block| {
        const block_area = utils.rectangle(block.x, block.y, block.width, block.height);

        // Horizontal
        if (utils.aabb_collides(block_area, utils.rectangle(self.x + self.x_speed, self.y, self.width, self.height))) {
            if (self.x_speed < 0) self.*.x = block.x + block.width else self.*.x = block.x - self.width;
            self.*.x_speed = 0;
        }

        // Vertical
        if (utils.aabb_collides(block_area, utils.rectangle(self.x, self.y - self.y_speed, self.width, self.height))) {
            if (self.y_speed < 0) {
                if (@hasField(@TypeOf(self.*), "grounded")) self.*.grounded = true;
                self.*.y = block.y - self.height;
            } else self.*.y = block.y + block.height;
            self.*.y_speed = 0;
        }
    }

    // Apply speed
    self.*.x += self.*.x_speed;
    self.*.y -= self.*.y_speed;
}
