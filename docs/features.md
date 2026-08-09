# Zamgba SDK Features Plan

The Zamgba SDK provides high-level APIs for 2D games on the Game Boy Advance. Its primary goal is to hide hardware details and provide a smooth, modern developer experience.

## Planned Features

1. **2D Graphics**
   - [ ] Sprite maps (Tile/Map modes)
   - [ ] Picture mode (Bitmap modes)
   - [x] Architecture Planning (Tiered approach)
   - [ ] High-level abstractions for palettes and object attributes (OAM) - *In Progress*

2. **Architecture Layers (New)**
   - **Tier 1 (HAL):** `zamgba.hal` - Hardware limits, memory, registers.
   - **Tier 2 (SYS):** `zamgba.sys` - OAM shadow, VRAM allocators, state tracking.
   - **Tier 3 (ENGINE):** `zamgba.engine` - High-level entities (Sprite, Camera, TileMap).

2. **Audio**
   - PSG (Programmable Sound Generator / Chiptune) support
   - Direct Sound (PCM) support

3. **Save System**
   - High-level state persistence
   - Hardware-dependent implementation (relies on external hardware/emulator capabilities like SRAM, Flash, or EEPROM)

4. **Physics & Collision**
   - Built-in 2D box (AABB) collision engine
