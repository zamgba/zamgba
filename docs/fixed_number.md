# Fixed-Point Number Design for GBA (`Fixed24_8`)

This document explains the design principles, performance considerations, and usage of the 24.8 fixed-point arithmetic structure (`Fixed24_8`) in Zamgba.

---

## 1. Overview and Architecture

GBA uses an **ARM7TDMI** processor without a Floating-Point Unit (FPU). Any standard 32-bit floating-point operation (`f32`) incurs heavy software emulation (`__aeabi_fadd`, `__aeabi_fmul`, etc.) costing tens to hundreds of CPU cycles per calculation.

To achieve high-performance physics and collision detection, Zamgba uses a fixed-point representation:
- **Underlying Type**: `u32` (32 bits unsigned integer).
- **Format**: `Fixed24_8`
  - High 24 bits (Bits 8–31): Integer part.
  - Low 8 bits (Bits 0–7): Fractional part ($1 / 256 \approx 0.00390625$ resolution).

```
 31                          8 7         0
+-----------------------------+-----------+
|        Integer (24 bits)    | Frac (8b) |
+-----------------------------+-----------+
```

---

## 2. Preventing Runtime Floating-Point Overhead

### The Problem
Allowing dynamic float conversion at runtime (e.g. `Fixed24_8.fromFloat(dynamic_f32)`) risks silently pulling in compiler soft-float libraries and burning frame cycles.

### The Solution: Comptime-Guaranteed Literals
Zig provides the `comptime` parameter qualifier. By constraining the constructor parameter to `comptime f: comptime_float`, the conversion is strictly evaluated at compile time:

```zig
pub fn fromFloat(comptime f: comptime_float) Fixed24_8 {
    return .{ .raw = @as(u32, @intFromFloat(f * @as(comptime_float, scale))) };
}
```

1. **Zero Runtime Cost**:
   ```zig
   const speed = Fixed24_8.fromFloat(3.5);
   ```
   During compilation, `3.5 * 256.0 = 896.0` is computed directly by the compiler. The emitted machine code loads the immediate constant `0x380` (896) into a register in a single cycle:
   ```armasm
   mov r0, #896
   ```

2. **Compile-Time Safety Guarantee**:
   Passing a dynamic runtime float variable will fail at compile time:
   ```zig
   var dynamic_val: f32 = getSpeed();
   const speed = Fixed24_8.fromFloat(dynamic_val); // Compile Error!
   ```
   *Compiler output*: `error: value being passed to 'comptime' parameter is not known at compile-time`.

---

## 3. Alternative Construction Methods

For runtime values where fractions or parts are computed from integers:

- **`fromParts(integer: u32, fraction: u8)`**: Directly combines an integer and an 8-bit fraction counter (`(integer << 8) | fraction`).
- **`fromFraction(integer: u32, num: u32, den: u32)`**: Constructs value from rational numbers (e.g. `fromFraction(3, 1, 2)` for $3 + \frac{1}{2}$).
- **`fromInt(i: u32)`**: Simple whole integer constructor (`i << 8`).

---

## 4. Assignment, Passing, and Memory Semantics

### Direct Assignment (`=`)
Because `Fixed24_8` wraps a single 32-bit field (`raw: u32`), instances can and should be copied using standard assignment:

```zig
var a = Fixed24_8.fromFloat(3.5);
var b: Fixed24_8 = a; // Direct copy
```

### Efficiency on ARM7TDMI
1. **Single-Cycle Copy**:
   A 32-bit value fits exactly into an ARM core register (`r0`–`r12`). Copying values between variables compiles into a single instruction (`mov r1, r0` or `ldr`/`str`), requiring only 1 clock cycle.
2. **Pass by Value**:
   Functions accept `Fixed24_8` parameters by value instead of pointers. Per the ARM Architecture Procedure Call Standard (AAPCS), up to 4 arguments are passed directly in registers `r0`–`r3` without memory or pointer dereference overhead:
   ```zig
   pub fn add(self: Fixed24_8, other: Fixed24_8) Fixed24_8 {
       return .{ .raw = self.raw + other.raw };
   }
   ```
3. **Batch Copying**:
   When copying slices or arrays of `Fixed24_8`, use `@memcpy`:
   ```zig
   @memcpy(dest_slice, src_slice);
   ```
