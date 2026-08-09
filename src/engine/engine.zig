const hal = @import("zamgba-hal");
const sys = @import("zamgba-sys");

pub const Sprite = @import("sprite.zig").Sprite;

pub const Engine = struct {
    oam: sys.oam.OamManager,
    sprite_count: usize,

    pub fn init() Engine {
        var oam = sys.oam.OamManager{};
        oam.init();
        return .{
            .oam = oam,
            .sprite_count = 0,
        };
    }

    /// Should be called at the end of the game loop to complete the frame.
    /// 1. Waits for the display to finish drawing the current frame (VBlank).
    /// 2. Commits the staged frame graphics (OAM shadow) to GBA hardware.
    /// 3. Resets the frame-level state (like sprite slot allocators) so the next frame starts fresh.
    pub fn nextFrame(self: *Engine) void {
        // Wait for VBlank
        hal.waitForVBlank();

        // Flush shadow memory to hardware
        self.oam.copyToHardware();

        // Reset the sprite count so the next frame draws from slot 0
        self.sprite_count = 0;
    }

    /// Registers a high-level sprite to be rendered in the current frame.
    /// This dynamically maps the high-level sprite into the next available OAM slot.
    pub fn drawSprite(self: *Engine, spr: *const Sprite) void {
        if (self.sprite_count >= 128) return; // GBA hardware limit
        self.oam.shadow[self.sprite_count] = spr.toOamAttr();
        self.sprite_count += 1;
    }
};
