# Zamgba SDK Architectural Design

The Zamgba SDK utilizes a consolidated, highly pragmatic **2-Layer Architecture** designed to completely isolate the GBA's bare-metal complexities from the user-facing game logic.

---

```mermaid
graph TD
    subgraph High-Level Framework (Developer Facing)
        E[engine.Engine] --> S[engine.Sprite]
        E --> G[gfx2d.Drawing Algorithms]
    end

    subgraph Low-Level Core (Under the Hood)
        O[sys.oam.OamManager] --> H[hal.Display]
        O --> R[hal.MemorySections]
    end

    E ==>|1. Synchronizes and flushes graphics to| O
    S ==>|2. Translates logical coordinates to| O
```

---

## 1. The Low-Level Core (Under the Hood)

This layer acts as the GBA's **Hardware Driver Layer**. It handles direct physical registers, volatile memory segments, and strict hardware constraints. Game developers rarely touch this layer directly.

### A. Hardware Abstraction Layer (`zamgba.hal`)
Maps GBA physical registers and exposes safe, atomic timing controls.
*   **`hal.MemorySections`**: Direct pointers to physical segments like VRAM (`0x06000000`), PALRAM (`0x05000000`), and OAM (`0x07000000`).
*   **`hal.Display`**: Configurations for GBA hardware register flags (Modes 0-5, Object enable, 1D/2D sprite mapping).
*   **`hal.waitForVBlank()`**: Synchronizes the CPU game loop with the hardware display beam, blocking execution until the brief vertical blanking window starts.

### B. Subsystem Managers (`zamgba.sys`)
Workarounds for hardware limits (such as the GBA's limit of exactly 128 hardware sprites).
*   **`sys.oam.OamManager`**: Implements **OAM Shadowing** using an EWRAM buffer `shadow: [128]ObjAttr`. Logic updates occur safely in EWRAM, and `copyToHardware()` copies them instantly during VBlank to prevent tearing.

---

## 2. The High-Level Framework (Developer Facing)

This is the **Game Engine Layer**. It is the primary API interface for the game developer, combining game loop orchestration, logical entities, and 2D drawing routines.

### A. Engine Orchestration (`zamgba.engine`)
*   **`engine.Sprite`**: A high-level entity representing a renderable object on screen. Holds friendly logical variables (`x: i32`, `y: i32`, `width`, `height`). It uses `toOamAttr()` to automatically calculate the GBA's complex shape/size bitmasks under the hood.
*   **`engine.Engine`**: 
    *   **`drawSprite(spr)`**: Dynamically maps high-level sprites to the next available physical slot (0 to 127) for the current frame.
    *   **`nextFrame()`**: Bundles frame timing (`hal.waitForVBlank()`), graphics flushing (`oam.copyToHardware()`), and dynamic sprite slot resets.
    *   **`run(context)`**: The compile-time monomorphized loop runner. It accepts either:
        1.  **Static Namespaces (`@This()` of a file)**: Treating files as implicit singleton structs for easy prototyping (state resides in file-scope variables).
        2.  **Instance Pointers (`&game`)**: Passing fully encapsulated game structs, supporting level transitions, and cartridge save state serialization (SRAM).

### B. 2D Graphics Algorithms (`zamgba.gfx2d`)
Provides platform-agnostic, mathematics-based drawing routines for procedural rendering on bitmap or canvas contexts.
*   **`gfx2d.drawLine(start, end, color, context)`**: Implements Bresenham's line algorithm to paint lines onto bitmap-backed drawing buffers.
*   **`gfx2d.Point2` / `gfx2d.Vector2`**: High-level geometric structures for manipulating coordinates.

---

## 3. Key Design Tradeoffs & Benefits

1.  **Zero-Cost Abstractions**: By leveraging Zig generics (`anytype` and `@hasDecl`), `Engine.run` resolves completely at compile-time. No virtual tables (vtables) or dynamic pointer dispatches are generated in the compiled machine code, leaving maximum performance for the GBA's 16.78 MHz CPU.
2.  **Encapsulation of Workarounds**: Hardware workarounds (like OAM Shadowing) are tucked away into the Low-Level Core, allowing developers to draw sprites smoothly in a standard 60 FPS update-and-render game loop.
