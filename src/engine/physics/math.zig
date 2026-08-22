const std = @import("std");

/// 24.8 fixed-point number based on u32.
/// High 24 bits for the integer part, low 8 bits for the fractional part.
pub const Fixed24_8 = struct {
    raw: u32,

    pub const fraction_bits = 8;
    pub const scale = 1 << fraction_bits;

    /// Create a Fixed24_8 from an integer.
    pub fn fromInt(i: u32) Fixed24_8 {
        return .{ .raw = i << fraction_bits };
    }

    /// Convert back to an integer (truncates the fractional part).
    pub fn toInt(self: Fixed24_8) u32 {
        return self.raw >> fraction_bits;
    }

    /// Add two fixed-point numbers.
    pub fn add(self: Fixed24_8, other: Fixed24_8) Fixed24_8 {
        return .{ .raw = self.raw + other.raw };
    }

    /// Subtract two fixed-point numbers.
    pub fn sub(self: Fixed24_8, other: Fixed24_8) Fixed24_8 {
        return .{ .raw = self.raw - other.raw };
    }

    /// Multiply two fixed-point numbers.
    pub fn mul(self: Fixed24_8, other: Fixed24_8) Fixed24_8 {
        // Use u64 to prevent overflow during multiplication
        const result_64 = @as(u64, self.raw) * @as(u64, other.raw);
        return .{ .raw = @as(u32, @intCast(result_64 >> fraction_bits)) };
    }

    /// Divide two fixed-point numbers.
    pub fn div(self: Fixed24_8, other: Fixed24_8) Fixed24_8 {
        const dividend_64 = @as(u64, self.raw) << fraction_bits;
        return .{ .raw = @as(u32, @intCast(dividend_64 / other.raw)) };
    }
};

test "Fixed24_8 fromInt and toInt" {
    const a = Fixed24_8.fromInt(5);
    try std.testing.expectEqual(@as(u32, 5 << 8), a.raw);
    try std.testing.expectEqual(@as(u32, 5), a.toInt());
}

test "Fixed24_8 add" {
    const a = Fixed24_8.fromInt(5);
    const b = Fixed24_8.fromInt(3);
    const c = a.add(b);
    try std.testing.expectEqual(@as(u32, 8), c.toInt());
    
    // Test with fractional parts
    const x = Fixed24_8{ .raw = (2 << 8) + 128 }; // 2.5
    const y = Fixed24_8{ .raw = (1 << 8) + 128 }; // 1.5
    const z = x.add(y);
    try std.testing.expectEqual(@as(u32, 4 << 8), z.raw); // 4.0
}

test "Fixed24_8 sub" {
    const a = Fixed24_8.fromInt(5);
    const b = Fixed24_8.fromInt(3);
    const c = a.sub(b);
    try std.testing.expectEqual(@as(u32, 2), c.toInt());
}

test "Fixed24_8 mul" {
    const a = Fixed24_8.fromInt(5);
    const b = Fixed24_8.fromInt(3);
    const c = a.mul(b);
    try std.testing.expectEqual(@as(u32, 15), c.toInt());

    // 1.5 * 2 = 3
    const x = Fixed24_8{ .raw = (1 << 8) + 128 }; // 1.5
    const y = Fixed24_8.fromInt(2);
    const z = x.mul(y);
    try std.testing.expectEqual(@as(u32, 3 << 8), z.raw);
}

test "Fixed24_8 div" {
    const a = Fixed24_8.fromInt(15);
    const b = Fixed24_8.fromInt(3);
    const c = a.div(b);
    try std.testing.expectEqual(@as(u32, 5), c.toInt());

    // 5 / 2 = 2.5
    const x = Fixed24_8.fromInt(5);
    const y = Fixed24_8.fromInt(2);
    const z = x.div(y);
    try std.testing.expectEqual(@as(u32, (2 << 8) + 128), z.raw);
}
