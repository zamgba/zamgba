const hal_joy = @import("zamgba-hal").joypad;

/// InputState maintains the current and previous states of the controller,
/// provides semantic methods to query input status, and tracks press duration.
pub const InputState = struct {
    current_raw: u16 = 0,
    previous_raw: u16 = 0,
    // Track duration (in frames) for each key (10 buttons total).
    durations: [10]u16 = .{0} ** 10,

    /// Updates the input state by reading the raw hardware input.
    /// Should be called once per frame.
    pub fn update(self: *InputState) void {
        self.previous_raw = self.current_raw;
        self.current_raw = hal_joy.readRaw();

        // Update press duration for each button
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            const mask = @as(u16, 1) << @intCast(i);
            if ((self.current_raw & mask) != 0) {
                // Increment duration if key is held
                if (self.durations[i] < 0xFFFF) {
                    self.durations[i] += 1;
                }
            } else {
                // Reset duration if key is released
                self.durations[i] = 0;
            }
        }
    }

    /// Returns the number of frames the key has been held.
    pub fn getDuration(self: *const InputState, key: hal_joy.Key) u16 {
        const index = @ctz(@intFromEnum(key));
        return self.durations[index];
    }

    /// Returns true if the specified key is currently held down.
    pub fn isPressed(self: *const InputState, key: hal_joy.Key) bool {
        return (self.current_raw & @intFromEnum(key)) != 0;
    }

    /// Returns true if the key was just pressed in the current frame.
    pub fn isJustPressed(self: *const InputState, key: hal_joy.Key) bool {
        const mask = @intFromEnum(key);
        return (self.current_raw & mask != 0) and (self.previous_raw & mask == 0);
    }

    /// Returns true if the key was released in the current frame.
    pub fn isJustReleased(self: *const InputState, key: hal_joy.Key) bool {
        const mask = @intFromEnum(key);
        return (self.current_raw & mask == 0) and (self.previous_raw & mask != 0);
    }
};
