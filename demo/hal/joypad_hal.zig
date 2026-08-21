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
    // Set Mode 3 (Bitmap mode) to draw directly to VRAM.
    var display = hal.Display.init();
    display.setMode3().writeRegister();

    // 2. Initialize Input
    var input = engine.input.InputState{};

    // 3. Game Loop
    while (true) {
        // Update input state at the start of the frame
        input.update();

        // 4. Input Logic: Draw based on button press
        // We use VRAM directly to clear and draw colors based on button state.
        // Screen resolution is 240x160.
        const vram = hal.MemorySections.VRAM;

        // Define a simple visual: if A is pressed, fill screen with White;
        // if B is pressed, fill with Red; else fill with Black.
        const color: u16 = if (input.isPressed(.A)) hal.Color.WHITE else if (input.isPressed(.B)) hal.Color.RED else hal.Color.BLACK;

        var i: usize = 0;
        while (i < 240 * 160) : (i += 1) {
            vram[i] = color;
        }

        // Wait for VBlank
        hal.waitForVBlank();
    }
}
