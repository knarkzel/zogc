const c = @import("c.zig");
const Video = @import("Video.zig");
const Texture = @import("Texture.zig");
const utils = @import("utils.zig");

pub fn run(video: *Video) void {
    // Texture
    var texture = Texture.init();
    texture.load_tpl("../assets/textures.tpl", 0);

    // Input
    _ = c.PAD_Init();
    var x: f32 = 0;
    var y: f32 = 0;
    var w: f32 = 32;
    var h: f32 = 32;

    var moveSpeed: f32 = 5;
    var deadzone: i8 = 30;

    while (true) {
        video.start();

        _ = c.PAD_ScanPads();
        var buttonsDown: u16 = c.PAD_ButtonsHeld(0);

        // TEMPORARY analog X input
        if (c.PAD_StickX(0) > deadzone or c.PAD_StickX(0) < -deadzone) {
            var value: i8 = c.PAD_StickX(0);

            if (value < 0) {
                x -= moveSpeed;
            } else {
                x += moveSpeed;
            }
        }

        // TEMPORARY analog Y input
        if (c.PAD_StickY(0) > deadzone or c.PAD_StickY(0) < -deadzone) {
            var value: i8 = c.PAD_StickY(0);

            if (value < 0) {
                y += moveSpeed;
            } else {
                y -= moveSpeed;
            }
        }

        // Left
        if (buttonsDown & c.PAD_BUTTON_LEFT != 0) {
            x -= moveSpeed;
        }

        // Right
        if (buttonsDown & c.PAD_BUTTON_RIGHT != 0) {
            x += moveSpeed;
        }

        // Up
        if (buttonsDown & c.PAD_BUTTON_UP != 0) {
            y -= moveSpeed;
        }

        // Down
        if (buttonsDown & c.PAD_BUTTON_DOWN != 0) {
            y += moveSpeed;
        }

        // Exit
        if (buttonsDown & c.PAD_BUTTON_START != 0) {
            break;
        }

        var xTemp: f32 = x;
        var yTemp: f32 = y;
        var wTemp: f32 = w;
        var hTemp: f32 = h;

        if (buttonsDown & c.PAD_BUTTON_B != 0) {
            xTemp = x - (w / 2);
            yTemp = y - (h / 2);
            wTemp *= 2;
            hTemp *= 2;
        }

        const points = utils.rectangle(xTemp, yTemp, wTemp, hTemp);
        const coords = utils.rectangle(0, 0, 0.5, 0.5);
        utils.texture(points, coords);
        video.finish();
    }
}
