const gba = @import("zamgba");
const hal = gba.hal;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "SPRITEINS",
    "ASPI",
    "00",
    0,
);

// Define a type-safe Game state structure.
// This struct completely encapsulates our state, making it highly modular
// and easy to serialize for SRAM/Flash save files.
const Game = struct {
    spr: engine.Sprite,
    dx: i32,

    /// Frame-by-frame tick method. Since we are passing an instance pointer,
    /// we have access to 'self' to update member variables dynamically.
    pub fn tick(self: *@This(), eng: *engine.Engine) void {
        // 1. Move the sprite using the instance state
        self.spr.x += self.dx;
        if (self.spr.x >= 240 - 8 or self.spr.x <= 0) {
            self.dx = -self.dx;
        }

        // 2. Draw the sprite via the engine
        eng.drawSprite(&self.spr);
    }
};

export fn main() noreturn {
    // 1. Initialize Display
    var display = hal.Display.init();
    display.setMode0().setObject().setObject1D().writeRegister();

    // 2. Setup Palette (PALRAM)
    const obj_pal = hal.MemorySections.PALRAM + 256;
    obj_pal[1] = hal.Color.WHITE;

    // 3. Setup Graphics (VRAM)
    const obj_vram = hal.MemorySections.VRAM + 32768;
    for (0..16) |i| {
        obj_vram[i] = 0x1111; // Palette index 1 for all pixels (White)
    }

    // 4. Instantiate our game state on the stack
    var game = Game{
        .spr = engine.Sprite.init(116, 76, 8, 8),
        .dx = 1,
    };
    game.spr.tile_index = 0;
    game.spr.palette_bank = 0;

    // 5. Initialize Engine Context
    var eng = engine.Engine.init();

    // 6. Start the engine loop, passing a POINTER to our instance.
    // The engine's compile-time run loop will cleanly locate and execute the instance's tick() method.
    eng.run(&game);
}
