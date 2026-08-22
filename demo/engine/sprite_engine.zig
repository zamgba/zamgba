const gba = @import("zamgba");
const hal = gba.hal;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "SPRITENG",
    "ASPE",
    "00",
    0,
);

// File-level globals. Since every Zig file is an implicit struct, these
// act as our clean Level/Game state fields without polluting other namespaces.
var spr: engine.Sprite = undefined;
var dx: i32 = 1;

/// The primary frame update callback for the active level/game.
/// This runs automatically on every frame within our engine loop.
pub fn tick(eng: *engine.Engine) void {
    // 1. Move the high-level sprite's position
    spr.x += dx;
    if (spr.x >= 240 - @as(i32, @intCast(spr.width)) or spr.x <= 0) {
        dx = -dx;
    }

    // 2. Draw the sprite (stages it dynamically in the next available OAM slot)
    eng.drawSprite(&spr);
}

export fn main() noreturn {
    // 1. Initialize Display (We still need to configure the hardware registers initially)
    var display = hal.Display.init();
    display.setMode0().setObject().setObject1D().writeRegister();

    // 2. Initialize high-level sprite state (16x32 rectangle sprite)
    spr = engine.Sprite.init(112, 64, 16, 32);
    spr.tile_index = 0;
    spr.palette_bank = 0;

    // 3. Upload solid cyan color tile graphics & palette to hardware
    spr.uploadSolidColor(engine.Color.CYAN) catch {};

    // 4. Initialize Engine Context
    var eng = engine.Engine.init();

    // 5. Start the engine loop, passing @This() (our current file-struct type)
    // The engine's compile-time run loop will cleanly locate and execute our tick() method.
    eng.run(@This());
}
