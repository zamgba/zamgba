const std = @import("std");
const Point2 = @import("point.zig").Point2;

/// Draws a line from p0 to p1 using Bresenham's line algorithm.
/// `context` is a pointer to a struct that represents the drawing surface.
/// It must expose a `drawPixel(self: @TypeOf(context), x: i32, y: i32, c: u16) void` method.
pub fn drawLine(
    p0: Point2,
    p1: Point2,
    color: u16,
    context: anytype,
) void {
    var x = p0.x;
    var y = p0.y;

    var dx: i32 = p1.x - p0.x;
    if (dx < 0) dx = -dx;

    var dy: i32 = p1.y - p0.y;
    if (dy < 0) dy = -dy;
    dy = -dy;

    const sx: i32 = if (p0.x < p1.x) 1 else -1;
    const sy: i32 = if (p0.y < p1.y) 1 else -1;

    var err = dx + dy;

    while (true) {
        context.drawPixel(x, y, color);
        if (x == p1.x and y == p1.y) break;
        const e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
}

test "drawLine vertical" {
    const TestContext = struct {
        vram: [20][20]u16 = std.mem.zeroes([20][20]u16),

        fn drawPixel(ctx: *@This(), x: i32, y: i32, c: u16) void {
            if (x >= 0 and x < 20 and y >= 0 and y < 20) {
                ctx.vram[@intCast(y)][@intCast(x)] = c;
            }
        }
    };

    var ctx = TestContext{};
    drawLine(Point2.init(5, 5), Point2.init(5, 10), 0xFFFF, &ctx);

    try std.testing.expectEqual(@as(u16, 0xFFFF), ctx.vram[5][5]);
    try std.testing.expectEqual(@as(u16, 0xFFFF), ctx.vram[10][5]);
    try std.testing.expectEqual(@as(u16, 0), ctx.vram[4][5]);
    try std.testing.expectEqual(@as(u16, 0), ctx.vram[11][5]);
}

test "drawLine diagonal" {
    const TestContext = struct {
        vram: [20][20]u16 = std.mem.zeroes([20][20]u16),

        fn drawPixel(ctx: *@This(), x: i32, y: i32, c: u16) void {
            if (x >= 0 and x < 20 and y >= 0 and y < 20) {
                ctx.vram[@intCast(y)][@intCast(x)] = c;
            }
        }
    };

    var ctx = TestContext{};
    drawLine(Point2.init(0, 0), Point2.init(5, 5), 0x1234, &ctx);

    try std.testing.expectEqual(@as(u16, 0x1234), ctx.vram[0][0]);
    try std.testing.expectEqual(@as(u16, 0x1234), ctx.vram[3][3]);
    try std.testing.expectEqual(@as(u16, 0x1234), ctx.vram[5][5]);
    try std.testing.expectEqual(@as(u16, 0), ctx.vram[0][1]);
    try std.testing.expectEqual(@as(u16, 0), ctx.vram[6][6]);
}
