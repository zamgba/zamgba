const gba = @import("zamgba");
const hal = gba.hal;
const sys = gba.sys;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "SECOND",
    "ASEE",
    "00",
    0,
);

export fn main() noreturn {
    // 1. Initialize Display
    // We set Mode 0 (Tilemap mode) which is common for 2D games,
    // and enable objects (sprites) to render them.
    var display = hal.Display.init();
    display.setMode0().setObject().setObject1D().writeRegister();

    // 2. Initialize OAM Manager
    var oam = sys.oam.OamManager{};
    oam.init();

    // Copy initialized shadow to hardware to clear any garbage sprites
    oam.copyToHardware();

    // 3. Game Loop
    while (true) {
        // Wait for VBlank (hal.waitForVBlank is missing, so we'd typically poll REG_VCOUNT or write an interrupt)
        // Here we just continually copy OAM data to hardware as a placeholder loop
        // In a real game, this happens exactly once per frame during VBlank.
        // oam.copyToHardware();
    }
}
