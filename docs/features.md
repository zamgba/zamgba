# Zamgba SDK Features Plan

The Zamgba SDK provides high-level APIs for 2D games on the Game Boy Advance. Its primary goal is to hide hardware details and provide a smooth, modern developer experience.

## Planned Features

1. **2D Graphics**
   - Sprite maps (Tile/Map modes)
   - Picture mode (Bitmap modes)
   - High-level abstractions for palettes and object attributes (OAM)

2. **Audio**
   - PSG (Programmable Sound Generator / Chiptune) support
   - Direct Sound (PCM) support

3. **Save System**
   - High-level state persistence
   - Hardware-dependent implementation (relies on external hardware/emulator capabilities like SRAM, Flash, or EEPROM)

4. **Physics & Collision**
   - Built-in 2D box (AABB) collision engine
