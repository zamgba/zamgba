pub const Point2 = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point2 {
        return .{
            .x = x,
            .y = y,
        };
    }
};
