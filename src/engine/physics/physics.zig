pub const math = @import("math.zig");
pub const Fixed24_8 = math.Fixed24_8;

pub const aabb = @import("aabb.zig");
pub const AABB = aabb.AABB;

test {
    _ = math;
    _ = aabb;
}
