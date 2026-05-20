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

/// A hardware-backed drawing context for GBA's Mode 5.
/// Mode 5 is a 160x128 resolution bitmap mode with 16-bit color and supports page flipping.
pub const Mode5Context = struct {
    page_base: [*]volatile u16,

    pub fn init(page: u1) Mode5Context {
        // Page 0: 0x06000000, Page 1: 0x0600A000
        // Since VRAM is a u16 pointer, 0xA000 bytes = 0x5000 u16 elements
        const offset: usize = if (page == 0) 0 else 0x5000;
        return .{
            .page_base = gba.MemorySections.VRAM + offset,
        };
    }

    /// Implements the pixel drawing interface required by `zamgba-gfx2d`.
    pub fn drawPixel(ctx: *@This(), x: i32, y: i32, color: u16) void {
        if (x >= 0 and x < 160 and y >= 0 and y < 128) {
            const index = @as(usize, @intCast(y)) * 160 + @as(usize, @intCast(x));
            ctx.page_base[index] = color;
        }
    }
};
