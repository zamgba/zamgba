# Global State and Memory Initialization

Unlike modern operating systems, the Game Boy Advance (GBA) has no OS to automatically load executable sections into memory. It boots directly from the read-only Game Pak ROM (`pakrom`). 

When you write standard Zig programs, you might use file-level variables or global state:

```zig
var spr: Sprite = undefined; // Goes to the .bss section (zero-initialized)
var dx: i32 = 1;             // Goes to the .data section (has an initial value)
```

Because ROM is strictly read-only, mutating these variables at runtime will silently fail if they remain in ROM. To support mutable global state on the GBA, these sections must be mapped to system RAM (like EWRAM) and explicitly initialized during the boot process.

## 1. Linker Script (`gba.ld`)

The linker script must direct `.bss` and `.data` symbols to `ewram`. Crucially, `.data` variables need their initial values stored in ROM so they aren't lost when the device loses power. We use `AT>pakrom` to tell the linker: "Set the runtime memory address (VMA) to EWRAM, but store the actual data (LMA) in the Game Pak ROM."

```ld
    .data : {
        _sidata = LOADADDR(.data);
        _sdata = .;
        *(.data .data.*);
        _edata = .;
    } > ewram AT>pakrom

    .bss : {
        _sbss = .;
        *(.bss .bss.*);
        _ebss = .;
    } > ewram
```

## 2. Boot Routine (`_boot`)

Before the `main()` function is called, our manual startup assembly (`src/hal/hal.zig`) must physically prepare the memory environment using the boundary symbols (`_sbss`, `_sdata`, etc.) provided by the linker script:

- **`zeroBss()`**: Iterates through the `.bss` block in EWRAM and zeroes out the memory.
- **`copyDataToEWRAM()`**: Copies the exact byte values from the ROM storage address (`_sidata`) into the designated EWRAM address range (`_sdata` to `_edata`).

If these steps are omitted, `.bss` will contain random garbage data from power-on, and `.data` variables will never receive their initial values, causing the game to behave unpredictably or crash.
