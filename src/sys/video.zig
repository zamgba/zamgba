const hal = @import("zamgba-hal");

/// Provides hardware-synchronized video operations for subsystems and engines.
pub const VideoManager = struct {
    /// Blocks the CPU until the display reaches the Vertical Blanking period.
    /// Used to safely synchronize frame updates without graphical tearing.
    pub fn waitForVBlank() void {
        hal.waitForVBlank();
    }
};
