const gba = @import("zamgba");
const hal = gba.hal;
const sys = gba.sys;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "SPRITENG",
    "ASPE",
    "00",
    0,
);

export fn main() noreturn {
    // 1. Initialize Display (We still need to configure the hardware registers initially)
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

    // 4. Initialize OAM Manager (Tier 2 Subsystem)
    var oam = sys.oam.OamManager{};
    oam.init();

    // 5. Create a High-Level Sprite (Tier 3 Engine API)
    // We instantiate a Sprite struct at (116, 76), with size 8x8.
    var spr = engine.Sprite.init(116, 76, 8, 8);
    spr.tile_index = 0; // Point to the first tile we filled in VRAM
    spr.palette_bank = 0; // Use the first palette bank (which has white at index 1)

    var dx: i32 = 1;

    // 6. Game Loop
    while (true) {
        // Move the high-level sprite's position
        spr.x += dx;
        if (spr.x > 240 - 8 or spr.x < 0) {
            dx = -dx;
        }

        // Translate the updated high-level properties down to the shadow slot
        oam.shadow[0] = spr.toOamAttr();

        // Wait for VBlank to start to prevent tearing on screen
        hal.waitForVBlank();

        // Flush shadow memory to GBA hardware
        oam.copyToHardware();
    }
}
