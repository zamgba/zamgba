# Compiling Zamgba

## Boot Function and Calling Conventions

When writing boot code for the Game Boy Advance (GBA) in Zig, it is critical to use the `callconv(.naked)` calling convention for the entry point (e.g., `_start`). 

### Why is `callconv(.naked)` required?

A "naked" function is a compiler directive that tells the Zig compiler to omit the standard function prologue and epilogue (e.g., instructions like `push {r7, lr}` that set up and tear down the stack frame). 

In low-level GBA programming, the `_start` function is mapped directly after the ROM header. The hardware expects exact, raw ARM/Thumb instructions at this location to initialize the system modes, set up the stack pointers, and jump to the main boot sequence. 

- **Before Zig 0.16.0**: The compiler was sometimes lenient and might not emit a prologue for `export` functions containing purely inline assembly.
- **Zig 0.16.0 and later**: The compiler became stricter and consistently emits standard ABI prologues for exported functions by default. 

If a prologue is injected before the manual boot assembly, the GBA hardware interprets those instructions incorrectly during the boot sequence (often due to being in the wrong execution mode), which results in a silent crash (typically a blank white screen). Using `callconv(.naked)` prevents the compiler from adding any automatic stack management instructions, leaving the raw inline assembly completely untouched.

### History of the naming convention

Note that prior to Zig 0.14.0, the convention was capitalized as `callconv(.Naked)`. Zig 0.14.0 renamed it to `callconv(.naked)` to match the language's conventions for declaration literals, while keeping the capitalized version as deprecated. As of 0.16.0, `.Naked` is removed, so `.naked` must be used.
