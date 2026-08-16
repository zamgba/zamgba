/// OAM hardware definition
/// A single OAM entry is 64 bits (8 bytes):
/// attr0 (16-bit), attr1 (16-bit), attr2 (16-bit), affine (16-bit).
pub const ObjAttr = packed struct {
    attr0: u16,
    attr1: u16,
    attr2: u16,
    fill: u16, // padding / affine index
};
