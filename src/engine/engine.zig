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
        sys.video.VideoManager.waitForVBlank();

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

    /// Starts the game loop. Automatically detects if you are passing:
    /// 1. A static namespace/type (e.g., `@This()` representing a Zig file-struct).
    /// 2. An instantiated struct pointer (e.g., `&game` containing state fields).
    /// Enforces at compile-time that a public `tick` function/method is defined.
    pub fn run(self: *Engine, context: anytype) noreturn {
        const T = @TypeOf(context);
        if (T == type) {
            // Static namespace/file context
            const has_tick = @hasDecl(context, "tick");
            if (!has_tick) {
                @compileError("Context type must define a public 'tick(eng: *Engine) void' function.");
            }
            while (true) {
                context.tick(self);
                self.nextFrame();
            }
        } else {
            // Instantiated object context
            const PtrInfo = @typeInfo(T);
            if (PtrInfo != .pointer) {
                @compileError("Engine.run must be passed a pointer for struct instances (e.g., &game).");
            }
            const ChildType = PtrInfo.pointer.child;
            const has_tick = @hasDecl(ChildType, "tick");
            if (!has_tick) {
                @compileError("Instance type must define a public 'tick(eng: *Engine) void' method.");
            }
            while (true) {
                context.tick(self);
                self.nextFrame();
            }
        }
    }
};
