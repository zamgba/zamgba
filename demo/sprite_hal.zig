const gba = @import("zamgba");
const hal = gba.hal;
const sys = gba.sys;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "SPRITEHAL",
    "ASPR",
    "00",
    0,
);

export fn main() noreturn {
    // 1. Initialize Display
    // We set Mode 0 (Tilemap mode) which is common for 2D games,
    // and enable objects (sprites) to render them.
    var display = hal.Display.init();
    display.setMode0().setObject().setObject1D().writeRegister();

    // 2. Setup Palette (PALRAM)
    // Object palette memory starts at 0x05000200.
    // Our PALRAM pointer is at 0x05000000, so we offset by 256 words (512 bytes).
    const obj_pal = hal.MemorySections.PALRAM + 256;
    obj_pal[1] = hal.Color.WHITE;

    // 3. Setup Graphics (VRAM)
    // Object VRAM starts at 0x06010000.
    // Our VRAM pointer is at 0x06000000, so we offset by 32768 words (65536 bytes).
    const obj_vram = hal.MemorySections.VRAM + 32768;

    // Fill the first 8x8 tile (4 bits per pixel).
    // Each u16 holds 4 pixels, so 16 words = 64 pixels.
    for (0..16) |i| {
        obj_vram[i] = 0x1111; // Palette index 1 for all pixels
    }

    // 4. Initialize OAM Manager
    var oam = sys.oam.OamManager{};
    oam.init();

    // Place the white sprite at the center of the screen.
    // Screen is 240x160. Sprite is 8x8.
    // Center X: (240 - 8) / 2 = 116
    // Center Y: (160 - 8) / 2 = 76
    oam.shadow[0] = .{
        .attr0 = 76, // Y coordinate = 76, 4bpp, Square shape
        .attr1 = 116, // X coordinate = 116, 8x8 size
        .attr2 = 0, // Tile index 0, Palette bank 0
        .fill = 0,
    };

    // Copy the shadow to hardware OAM to make it visible
    oam.copyToHardware();

    // 5. Game Loop
    while (true) {}
}
