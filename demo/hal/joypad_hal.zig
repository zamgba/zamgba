const gba = @import("zamgba");
const hal = gba.hal;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "JOYPADHAL",
    "AJOY",
    "00",
    0,
);

export fn main() noreturn {
    // 1. Initialize Display
    // Set Mode 3 (Bitmap mode) and enable BG2 to draw directly to VRAM.
    var display = hal.Display.init();
    display.setMode3().setBackground2().writeRegister();

    // 2. Initialize Input
    var input = engine.input.InputState{};

    // Box properties
    const box_size: i32 = 16;
    var box_x: i32 = (hal.Screen.WIDTH_PIXELS - box_size) / 2;
    var box_y: i32 = (hal.Screen.HEIGHT_PIXELS - box_size) / 2;
    var prev_x: i32 = box_x;
    var prev_y: i32 = box_y;

    const vram = hal.MemorySections.VRAM;

    // Clear entire screen to Black once at startup
    var i: usize = 0;
    while (i < hal.Screen.WIDTH_PIXELS * hal.Screen.HEIGHT_PIXELS) : (i += 1) {
        vram[i] = hal.Color.BLACK;
    }

    var frame: u32 = 0;

    // 3. Game Loop
    while (true) {
        frame +%= 1;

        // Update input state at the start of the frame
        input.update();

        // ---------------------------------------------------------
        // DEBUG: Read hardware register directly as a fallback check
        const raw_key = hal.MemorySections.REG_KEYINPUT.*;
        const left_pressed = (raw_key & (1 << 5)) == 0 or input.isPressed(.Left);
        const right_pressed = (raw_key & (1 << 4)) == 0 or input.isPressed(.Right);
        const up_pressed = (raw_key & (1 << 6)) == 0 or input.isPressed(.Up);
        const down_pressed = (raw_key & (1 << 7)) == 0 or input.isPressed(.Down);
        const a_pressed = (raw_key & (1 << 0)) == 0 or input.isPressed(.A);
        const b_pressed = (raw_key & (1 << 1)) == 0 or input.isPressed(.B);
        // ---------------------------------------------------------

        // Move box based on D-pad input with boundary clamping
        if (left_pressed) {
            box_x -= 2;
            if (box_x < 0) box_x = 0;
        }
        if (right_pressed) {
            box_x += 2;
            if (box_x > hal.Screen.WIDTH_PIXELS - box_size) {
                box_x = hal.Screen.WIDTH_PIXELS - box_size;
            }
        }
        if (up_pressed) {
            box_y -= 2;
            if (box_y < 0) box_y = 0;
        }
        if (down_pressed) {
            box_y += 2;
            if (box_y > hal.Screen.HEIGHT_PIXELS - box_size) {
                box_y = hal.Screen.HEIGHT_PIXELS - box_size;
            }
        }

        // Determine box color (A -> Red, B -> Yellow, Default -> White)
        const box_color: u16 = if (a_pressed)
            hal.Color.RED
        else if (b_pressed)
            hal.Color.YELLOW
        else
            hal.Color.WHITE;

        // Erase old box position
        var sy: i32 = 0;
        while (sy < box_size) : (sy += 1) {
            var sx: i32 = 0;
            while (sx < box_size) : (sx += 1) {
                const pixel_x = @as(usize, @intCast(prev_x + sx));
                const pixel_y = @as(usize, @intCast(prev_y + sy));
                vram[pixel_y * hal.Screen.WIDTH_PIXELS + pixel_x] = hal.Color.BLACK;
            }
        }

        // Draw box at current position
        sy = 0;
        while (sy < box_size) : (sy += 1) {
            var sx: i32 = 0;
            while (sx < box_size) : (sx += 1) {
                const pixel_x = @as(usize, @intCast(box_x + sx));
                const pixel_y = @as(usize, @intCast(box_y + sy));
                vram[pixel_y * hal.Screen.WIDTH_PIXELS + pixel_x] = box_color;
            }
        }

        // Debug indicator: draw a blinking pixel at top-left to ensure loop is running
        vram[0] = if (frame % 60 < 30) hal.Color.MAG else hal.Color.CYAN;

        prev_x = box_x;
        prev_y = box_y;

        // Wait for VBlank
        hal.waitForVBlank();
    }
}
