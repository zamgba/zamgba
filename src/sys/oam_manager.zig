const hal = @import("zamgba-hal");

/// OAM shadow memory block (128 objects)
/// A single OAM entry is 64 bits (8 bytes):
/// attr0 (16-bit), attr1 (16-bit), attr2 (16-bit), affine (16-bit).
pub const ObjAttr = packed struct {
    attr0: u16,
    attr1: u16,
    attr2: u16,
    fill: u16, // padding / affine index
};

pub const OamManager = struct {
    /// The shadow OAM. We manipulate this safely during the frame.
    shadow: [128]ObjAttr = undefined,

    /// Initializes the shadow OAM by hiding all sprites (setting Y outside screen).
    pub fn init(self: *OamManager) void {
        for (&self.shadow) |*obj| {
            // attr0 bits 0-7 are Y coordinate. Setting to 160 (Screen height) hides it.
            // bit 8 is affine/double size, bit 9 is double size/disable
            // setting bit 8 and 9 appropriately disables it or pushes offscreen.
            obj.* = .{
                .attr0 = 160, // Pushed offscreen
                .attr1 = 0,
                .attr2 = 0,
                .fill = 0,
            };
        }
    }

    /// Update the hardware OAM with the shadow copy.
    /// Should only be called during VBlank to avoid tearing.
    pub fn copyToHardware(self: *OamManager) void {
        const hw_oam = @as([*]volatile ObjAttr, @ptrCast(@alignCast(hal.MemorySections.OAM)));

        // A simple copy. In the future, this should be optimized using DMA3.
        for (self.shadow, 0..) |obj, i| {
            hw_oam[i] = obj;
        }
    }
};
