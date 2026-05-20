const std = @import("std");

/// Draws a line from (x0, y0) to (x1, y1) using Bresenham's line algorithm.
/// `context` is a pointer to a struct that represents the drawing surface.
/// `drawPixel` is a function that takes the context, x, y, and color, and draws a pixel.
pub fn drawLine(
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    color: u16,
    context: anytype,
    comptime drawPixel: fn (ctx: @TypeOf(context), x: i32, y: i32, c: u16) void,
) void {
    var x = x0;
    var y = y0;

    var dx: i32 = x1 - x0;
    if (dx < 0) dx = -dx;

    var dy: i32 = y1 - y0;
    if (dy < 0) dy = -dy;
    dy = -dy;

    const sx: i32 = if (x0 < x1) 1 else -1;
    const sy: i32 = if (y0 < y1) 1 else -1;

    var err = dx + dy;

    while (true) {
        drawPixel(context, x, y, color);
        if (x == x1 and y == y1) break;
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
    drawLine(5, 5, 5, 10, 0xFFFF, &ctx, TestContext.drawPixel);

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
    drawLine(0, 0, 5, 5, 0x1234, &ctx, TestContext.drawPixel);

    try std.testing.expectEqual(@as(u16, 0x1234), ctx.vram[0][0]);
    try std.testing.expectEqual(@as(u16, 0x1234), ctx.vram[3][3]);
    try std.testing.expectEqual(@as(u16, 0x1234), ctx.vram[5][5]);
    try std.testing.expectEqual(@as(u16, 0), ctx.vram[0][1]);
    try std.testing.expectEqual(@as(u16, 0), ctx.vram[6][6]);
}
