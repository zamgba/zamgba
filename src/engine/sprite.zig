const sys = @import("zamgba-sys");

/// A high-level representation of a Sprite.
/// This structure holds engine-level data (x, y, scale, texture)
/// which is automatically translated to hardware `ObjAttr` format by the engine.
pub const Sprite = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    
    /// Hardware tile index start
    tile_index: u16,
    
    /// Palette bank (0-15)
    palette_bank: u8,
    
    visible: bool = true,

    pub fn init(x: i32, y: i32, width: u32, height: u32) Sprite {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .tile_index = 0,
            .palette_bank = 0,
        };
    }
    
    /// Compiles the engine-level sprite into a hardware OAM attribute.
    pub fn toOamAttr(self: *const Sprite) sys.oam.ObjAttr {
        if (!self.visible) {
            return .{ .attr0 = 160, .attr1 = 0, .attr2 = 0, .fill = 0 };
        }
        
        // Basic encoding. (Requires proper shape/size bitmasking based on width/height in a real implementation)
        const y_hw: u16 = @as(u16, @intCast(@max(0, self.y))) & 0x00FF;
        const x_hw: u16 = @as(u16, @intCast(@max(0, self.x))) & 0x01FF;
        
        return .{
            .attr0 = y_hw, // Color mode etc omitted for brevity
            .attr1 = x_hw, // Size omitted for brevity
            .attr2 = self.tile_index | (@as(u16, self.palette_bank) << 12),
            .fill = 0,
        };
    }
};
