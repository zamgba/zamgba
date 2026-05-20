const gba = @import("gba.zig");

/// A hardware-backed drawing context for GBA's Mode 3.
/// Mode 3 is a 240x160 resolution bitmap mode with 16-bit color.
pub const Mode3Context = struct {
    vram: [*]volatile u16 = gba.MemorySections.VRAM,

    pub fn init() Mode3Context {
        return .{};
    }

    /// Implements the pixel drawing interface required by `zamgba-gfx2d`.
    pub fn drawPixel(ctx: *@This(), x: i32, y: i32, color: u16) void {
        // Bounds checking is essential to prevent writing outside VRAM
        if (x >= 0 and x < gba.Screen.WIDTH_PIXELS and y >= 0 and y < gba.Screen.HEIGHT_PIXELS) {
            const index = @as(usize, @intCast(y)) * gba.Screen.WIDTH_PIXELS + @as(usize, @intCast(x));
            ctx.vram[index] = color;
        }
    }
};
