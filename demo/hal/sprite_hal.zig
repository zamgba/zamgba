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

    var x: i32 = 116;
    var dx: i32 = 1;

    // 5. Game Loop
    while (true) {
        // Move the sprite horizontally
        x += dx;
        if (x > 240 - 8 or x < 0) {
            dx = -dx;
        }

        // Place the white sprite at the moving X coordinate, fixed Y coordinate
        oam.shadow[0] = .{
            .attr0 = 76, // Y coordinate = 76, 4bpp, Square shape
            .attr1 = @as(u16, @intCast(x)) & 0x01FF, // X coordinate = x, 8x8 size
            .attr2 = 0, // Tile index 0, Palette bank 0
            .fill = 0,
        };

        // Wait for VBlank before copying to hardware to avoid tearing
        hal.waitForVBlank();

        // Copy the shadow to hardware OAM to make changes visible
        oam.copyToHardware();
    }
}
