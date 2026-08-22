# GBA Boot Function Linkage and Section Layout

This document explains why boot functions (`_start`, `_boot`) in Zamgba must be declared with `export fn ... linksection(...)` directly rather than using comptime `@export` attributes, and how host unit test compatibility is maintained.

---

## 1. The GBA Memory Map and Linker Layout (`gba.ld`)

When a Game Boy Advance boots, the GBA BIOS validates the 228-byte ROM header and jumps directly to memory offset `0x080000E0` (immediately following the header in Cartridge ROM).

To satisfy this hardware requirement, `src/hal/gba.ld` defines a strict order in `.text`:

```ld
SECTIONS
{
    . = __text_start; /* 0x08000000 */

    .text : {
        KEEP(*(.gba.header));  /* 0x08000000 - 0x080000DF (Header) */
        KEEP(*(.gba.start));   /* 0x080000E0 (Entry point: _start) */
        KEEP(*(.gba.boot));    /* Initialization logic: _boot */
        KEEP(*(.gba.main));    /* User main function */
        *(.text*)
        . = ALIGN(4);
    } > pakrom
}
```

If `_start` is not placed strictly inside `.gba.start`, the linker places arbitrary code from `*(.text*)` at `0x080000E0`. The BIOS then jumps into invalid instructions, leading to a silent boot crash (blank white screen).

---

## 2. Direct `linksection(...)` vs `@export`

In Zig 0.16.0, there is a fundamental difference in how machine code is assigned to ELF sections between `export fn ... linksection(...)` and `@export`:

### Direct `linksection(...)`
When a function is declared with `export fn _start() linksection(".gba.start") callconv(.naked) void`, the section attribute is directly attached to the function symbol during LLVM / Zig code generation. The generated ARM machine code is placed directly into the `.gba.start` section in the target object file.

### Comptime `@export(&func, .{ .section = "..." })`
When `@export` is applied to a regular function (e.g., `fn _start_impl()`), Zig generates the function's machine code into the default `.text` section during codegen. `@export` creates an exported symbol name, but the underlying machine code remains in `.text`. As a result, `.gba.start` remains empty and the linker fails to place `_start` at `0x080000E0`.

---

## 3. Naked Calling Convention (`callconv(.naked)`)

`_start` executes before the ARM CPU stack pointers (`sp_irq`, `sp_usr`) are initialized. Using `callconv(.naked)` prevents the compiler from injecting function prologues (`push {r7, lr}`) or epilogues.

Combining `linksection(...)`, `callconv(.naked)`, and `export fn` is required for bare-metal boot routines in Zamgba:

```zig
export fn _start() linksection(".gba.start") callconv(.naked) void {
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\mov r0, #0x04000000
        \\str r0, [r0, #0x208]
        \\mov r0, #0x12
        \\msr cpsr, r0
        \\ldr sp, =__sp_irq
        \\mov r0, #0x10
        \\msr cpsr, r0
        \\ldr sp, =__sp_usr
        \\ldr r3, =_boot
        \\bx r3
    );
}
```

---

## 4. Host Unit Test Compatibility Pattern

Because unit tests run on the host machine (`x86_64` or `AArch64`), compiling GBA-specific inline ARM assembly (`.arm`, `.cpu arm7tdmi`) directly during `zig build test` causes host compilation errors.

To solve this without breaking GBA ROM section placement, GBA boot exports are wrapped in a conditional `comptime` struct block:

```zig
const builtin = @import("builtin");
const is_gba_target = (builtin.target.cpu.arch == .arm or builtin.target.cpu.arch == .thumb) and builtin.target.os.tag == .freestanding;

comptime {
    if (is_gba_target) {
        _ = struct {
            export fn _boot() linksection(".gba.boot") void { ... }
            export fn irqHandler() callconv(.naked) void { ... }
            export fn _start() linksection(".gba.start") callconv(.naked) void { ... }
        };
    }
}
```

- **When building GBA ROMs (`is_gba_target == true`)**: The `comptime` struct is instantiated, exporting `_start` and `_boot` with exact `linksection` attributes for `gba.ld`.
- **When running host unit tests (`is_gba_target == false`)**: The `comptime` block is skipped, preventing ARM assembly or section symbol collisions on desktop host targets.
