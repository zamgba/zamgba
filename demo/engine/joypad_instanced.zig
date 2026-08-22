const gba = @import("zamgba");
const hal = gba.hal;
const engine = gba.engine;

// The standard ROM header for the GBA BIOS
export var gameHeader linksection(".gba.header") = hal.setupROMHeader(
    "JOYPADINS",
    "AJPI",
    "00",
    0,
);

const Game = struct {
    spr: engine.Sprite,
    input: engine.input.InputState,
    current_color: engine.Color,

    pub fn tick(self: *@This(), eng: *engine.Engine) void {
        self.input.update();

        const speed: i32 = 2;
        const max_x: i32 = hal.Screen.WIDTH_PIXELS - @as(i32, @intCast(self.spr.width));
        const max_y: i32 = hal.Screen.HEIGHT_PIXELS - @as(i32, @intCast(self.spr.height));

        var new_color: ?engine.Color = null;

        if (self.input.isPressed(.Left)) {
            self.spr.x -= speed;
            if (self.spr.x <= 0) {
                self.spr.x = 0;
                new_color = engine.Color.YELLOW;
            }
        }
        if (self.input.isPressed(.Right)) {
            self.spr.x += speed;
            if (self.spr.x >= max_x) {
                self.spr.x = max_x;
                new_color = engine.Color.GREEN;
            }
        }
        if (self.input.isPressed(.Up)) {
            self.spr.y -= speed;
            if (self.spr.y <= 0) {
                self.spr.y = 0;
                new_color = engine.Color.RED;
            }
        }
        if (self.input.isPressed(.Down)) {
            self.spr.y += speed;
            if (self.spr.y >= max_y) {
                self.spr.y = max_y;
                new_color = engine.Color.WHITE;
            }
        }

        if (new_color) |c| {
            if (c.r != self.current_color.r or c.g != self.current_color.g or c.b != self.current_color.b) {
                self.current_color = c;
                self.spr.fillSolidColor(c) catch {};
            }
        }

        eng.drawSprite(&self.spr);
    }
};

export fn main() noreturn {
    var display = hal.Display.init();
    display.setMode0().setObject().setObject1D().writeRegister();

    const spr_width: u32 = 16;
    const spr_height: u32 = 16;
    const start_x: i32 = (hal.Screen.WIDTH_PIXELS - @as(i32, @intCast(spr_width))) / 2;
    const start_y: i32 = (hal.Screen.HEIGHT_PIXELS - @as(i32, @intCast(spr_height))) / 2;

    var game = Game{
        .spr = engine.Sprite.init(start_x, start_y, spr_width, spr_height),
        .input = .{},
        .current_color = engine.Color.WHITE,
    };
    game.spr.tile_index = 0;
    game.spr.palette_bank = 0;

    game.spr.fillSolidColor(game.current_color) catch {};

    var eng = engine.Engine.init();
    eng.run(&game);
}
