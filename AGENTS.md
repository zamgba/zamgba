# Zamgba Agent Guidelines

This document provides essential context for AI agents working in the `zamgba` repository.

## Project Overview
Zamgba is a self-learning project for Game Boy Advance (GBA) programming using the **Zig** programming language. It is primarily a set of example code following the classic [tonc](https://www.coranac.com/tonc/text/toc.htm) tutorial. It also acts as a library that other projects can consume to build GBA ROMs.

## Essential Commands

- **Build**: `zig build`
  - Generates ROMs in `zig-out/bin/` (e.g., `first.gba`).
  - Generates ELF format binaries (e.g., `first`) which are not executable on emulators but contain symbols and linker section info useful for debugging.
- **Test**: `zig build test`
  - *Gotcha*: Unit tests are compiled and executed on the **host machine**. GBA-specific code (e.g., manipulation of hardware registers) will not be covered by unit tests.
- **Run**: `mgba ./zig-out/bin/first.gba`
- **Debug**: `mgba -d ./zig-out/bin/first.gba` (assembly debugging)

## Architecture & Code Organization

- `build.zig`: The main build script. Exports a module so client projects can reference Zamgba's build logic (specifically `arm.addROM()`).
- `src/gba.zig`: The core library file. Contains memory section mappings, screen/color constants, and the low-level boot code.
- `src/gba.ld`: The linker script defining the memory layout for the ARM7tdmi architecture.
- `src/header.zig`: ROM header structure.
- `demo/first.zig`: The entry point for the demo ROM included in this project.

## Gotchas and Important Patterns

### GBA Boot Logic Workaround
The startup logic in `_start()` and `_boot()` intentionally uses inline assembly (`asm volatile`) rather than Zig's built-in `@hasDecl(root, "main")` to call the user's `main()` function. This is because `@hasDecl` is evaluated at compile time and led to an endless loop during boot. **Do not refactor the boot assembly to use `@hasDecl`.**

### Client Project Requirements
If configuring a client project to use this library:
1. The client's `build.zig` must call `@import("zamgba").arm.addROM()` to define a GBA-compatible target and handle the `objcopy` step to create the `.gba` file.
2. The client must register the GBA ROM header explicitly by calling `setupROMHeader()` (from `zamgba`).
3. The client must define the `main()` function with the `export` keyword so the boot sequence can locate the entry point.

### Platform
The target CPU is `arm7tdmi`. Keep this in mind when making architecture-specific optimizations or writing inline assembly.
