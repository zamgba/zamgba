pub const point = @import("point.zig");
pub const Point2 = point.Point2;

pub const line = @import("line.zig");
pub const drawLine = line.drawLine;

test {
    _ = @import("std").testing.refAllDecls(@This());
}
