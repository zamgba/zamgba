const REG_DISPCNT = @as(*volatile u16, @ptrFromInt(0x04000000));
const REG_DISPSTAT = @as(*volatile u16, @ptrFromInt(0x04000004));
const REG_VCOUNT = @as(*volatile u16, @ptrFromInt(0x04000006));

value: u16,

pub fn init() @This() {
    return @This(){
        .value = 0,
    };
}

pub fn writeRegister(self: *@This()) void {
    (REG_DISPCNT.*) = self.value;
}

pub fn loadRegister(self: *@This()) void {
    self.value = (REG_DISPCNT.*);
}

// DCNT_MODE
pub fn setMode0(self: *@This()) *@This() {
    self.value |= 0x0000;
    return self;
}
pub fn setMode1(self: *@This()) *@This() {
    self.value |= 0x0001;
    return self;
}
pub fn setMode2(self: *@This()) *@This() {
    self.value |= 0x0002;
    return self;
}
pub fn setMode3(self: *@This()) *@This() {
    self.value |= 0x0003;
    return self;
}
pub fn setMode4(self: *@This()) *@This() {
    self.value |= 0x0004;
    return self;
}
pub fn setMode5(self: *@This()) *@This() {
    self.value |= 0x0005;
    return self;
}

// DCNT_GB
pub fn isGBC() bool {
    return (REG_DISPCNT.*) & 0x08 == 0x08;
}

// DCNT_PAGE
pub fn selectPage1(self: *@This()) *@This() {
    self.value |= 0x0010;
    return self;
}
pub fn selectPage0(self: *@This()) *@This() {
    self.value &= 0xFFEF;
    return self;
}

pub fn isPage0() bool {
    return (REG_DISPCNT.*) & 0x0010 == 0;
}

pub fn isPage1() bool {
    return (REG_DISPCNT.*) & 0x0010 != 0;
}

pub fn getPage() u8 {
    if (((REG_DISPCNT.*) & 0x0010) == 0) {
        return 0;
    }
    return 1;
}

pub fn waitForVBlank() void {
    const REG_IE = @as(*volatile u16, @ptrFromInt(0x04000200));
    const REG_IME = @as(*volatile u16, @ptrFromInt(0x04000208));

    // Enable VBlank interrupt in DISPSTAT
    (REG_DISPSTAT.*) |= 0x0008;

    // Enable VBlank interrupt in IE
    REG_IE.* |= 0x0001;

    // Enable Master Interrupt
    REG_IME.* = 1;

    asm volatile ("swi 0x05" ::: .{
            .r0 = true,
            .r1 = true,
            .r2 = true,
            .r3 = true,
            .memory = true,
        });
}

pub fn flipPage() void {
    (REG_DISPCNT.*) ^= 0x0010;
}

// TODO
// DCNT_HB
// DCNT_OM
// DCNT_FB
// DCNT_BG{0-3}
pub fn setBackground0(self: *@This()) *@This() {
    self.value |= 0x0100;
    return self;
}

pub fn setBackground1(self: *@This()) *@This() {
    self.value |= 0x0200;
    return self;
}

pub fn setBackground2(self: *@This()) *@This() {
    self.value |= 0x0400;
    return self;
}

pub fn setBackground3(self: *@This()) *@This() {
    self.value |= 0x0800;
    return self;
}

pub fn unsetBackground0(self: *@This()) *@This() {
    self.value &= 0xFEFF;
    return self;
}

pub fn unsetBackground1(self: *@This()) *@This() {
    self.value &= 0xFDFF;
    return self;
}

pub fn unsetBackground2(self: *@This()) *@This() {
    self.value &= 0xFBFF;
    return self;
}

pub fn unsetBackground3(self: *@This()) *@This() {
    self.value &= 0xF7FF;
    return self;
}

pub const DCNT_OBJ: u16 = 0x1000;
pub const DCNT_OBJ_1D: u16 = 0x0040;

pub fn setObject(self: *@This()) *@This() {
    self.value |= DCNT_OBJ;
    return self;
}

pub fn unsetObject(self: *@This()) *@This() {
    self.value &= ~DCNT_OBJ;
    return self;
}

pub fn setObject1D(self: *@This()) *@This() {
    self.value |= DCNT_OBJ_1D;
    return self;
}

pub fn unsetObject1D(self: *@This()) *@This() {
    self.value &= ~DCNT_OBJ_1D;
    return self;
}
//
// REG_DISPSTAT
// REG_VCOUNT

// ===================================================================
// Unit tests
// ===================================================================

test "Display.SetModeAndBackground" {
    const std = @import("std");
    var disp = init();

    // Do not call .writeRegister() because it's only available when
    // running on a real GBA device. The address of REG_DISPCNT can
    // write to any result but what we want.
    _ = disp.setMode3().setBackground2();
    try std.testing.expect(disp.value == 0x0403);
}
