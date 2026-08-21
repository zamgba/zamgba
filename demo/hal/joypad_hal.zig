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

    const vram = hal.MemorySections.VRAM;

    // 3. Game Loop
    while (true) {
        // Update input state at the start of the frame
        input.update();

        // Move box based on D-pad input with boundary clamping
        if (input.isPressed(.Left)) {
            box_x -= 2;
            if (box_x < 0) box_x = 0;
        }
        if (input.isPressed(.Right)) {
            box_x += 2;
            if (box_x > hal.Screen.WIDTH_PIXELS - box_size) {
                box_x = hal.Screen.WIDTH_PIXELS - box_size;
            }
        }
        if (input.isPressed(.Up)) {
            box_y -= 2;
            if (box_y < 0) box_y = 0;
        }
        if (input.isPressed(.Down)) {
            box_y += 2;
            if (box_y > hal.Screen.HEIGHT_PIXELS - box_size) {
                box_y = hal.Screen.HEIGHT_PIXELS - box_size;
            }
        }

        // Clear screen to Black
        var i: usize = 0;
        while (i < hal.Screen.WIDTH_PIXELS * hal.Screen.HEIGHT_PIXELS) : (i += 1) {
            vram[i] = hal.Color.BLACK;
        }

        // Draw white box at current position
        var sy: i32 = 0;
        while (sy < box_size) : (sy += 1) {
            var sx: i32 = 0;
            while (sx < box_size) : (sx += 1) {
                const pixel_x = @as(usize, @intCast(box_x + sx));
                const pixel_y = @as(usize, @intCast(box_y + sy));
                vram[pixel_y * hal.Screen.WIDTH_PIXELS + pixel_x] = hal.Color.WHITE;
            }
        }

        // Wait for VBlank
        hal.waitForVBlank();
    }
}
