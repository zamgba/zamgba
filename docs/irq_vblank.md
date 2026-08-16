# Hardware Interrupts and VBlankIntrWait (SWI 0x05)

In GBA programming, waiting for the Vertical Blank (VBlank) is a critical part of the game loop to prevent screen tearing. The naive approach is "Busy Waiting" (polling the `REG_VCOUNT` hardware register in an endless `while` loop). However, this wastes 100% of the CPU cycles, drains battery life, and increases hardware temperature.

The optimal approach is to put the CPU into a low-power Halt state and let the GBA's hardware interrupt system wake it up exactly when VBlank occurs. This is achieved using the BIOS Software Interrupt `swi 0x05` (VBlankIntrWait).

## How VBlankIntrWait Works

The `swi 0x05` instruction is a call to the GBA BIOS. The wake-up process is a relay race involving the hardware, the BIOS, and our custom IRQ handler.

### 1. Hardware Trigger
First, we must configure the hardware to emit a signal when VBlank happens.
* We set the VBlank Interrupt flag in the Display Status register (`REG_DISPSTAT`).
* We enable VBlank interrupts in the Interrupt Enable register (`REG_IE`).
* We turn on the Master Interrupt Enable switch (`REG_IME`).

When we call `asm volatile ("swi 0x05")`, the BIOS halts the CPU. The CPU consumes very little power until the hardware emits the requested VBlank signal.

### 2. The Custom IRQ Handler (`irqHandler`)
When the VBlank hardware signal fires, the CPU wakes up and jumps into the BIOS Interrupt Dispatcher. The BIOS doesn't automatically know what to do; instead, it looks for a user-defined function pointer stored at `0x03007FFC` (`USER_IRQ_HANDLER`) and executes it.

Because the BIOS jumps in ARM state, our `irqHandler` must be written in pure `.arm` assembly (using `callconv(.naked)` in Zig) to prevent the thumb-mode compiler from emitting incompatible 16-bit instructions.

### 3. The Assembly Logic (Acknowledging the Wake-Up)

The core logic of the `irqHandler` is to acknowledge the interrupt and give the BIOS permission to return to the game loop. 

```armasm
@ Read REG_IF (0x04000202) -> Check what woke the CPU up
add r0, r0, #0x200
ldrh r2, [r0, #2]

@ Acknowledge REG_IF hardware interrupts
strh r2, [r0, #2]

@ Read BIOS_IF (0x03007FF8) -> Read the BIOS software interrupt flag
ldrh r3, [r1]

@ Acknowledge BIOS IntrWait interrupts -> The "Wake-Up Stamp"
orr r3, r3, r2
strh r3, [r1]

@ Return to BIOS IRQ dispatcher
bx lr
```

**Step-by-Step Breakdown:**

1. **`ldrh r2, [r0, #2]`**: The `[r0, #2]` syntax is ARM Base Register Addressing. With `r0` being `0x04000200`, this computes the physical address `0x04000202`, which is `REG_IF` (Interrupt Request Flags). We load this into `r2`. If VBlank fired, the 0th bit is `1` (i.e., `r2 = 0x0001`).
2. **`strh r2, [r0, #2]`**: By writing `0x0001` back to `REG_IF`, we acknowledge the hardware interrupt, telling the physical motherboard to stop sending the signal.
3. **`orr r3, r3, r2` (Bitwise OR)**: This is where the magic happens. We read the BIOS internal IntrWait flag memory (`BIOS_IF` at `0x03007FF8`) into `r3`, and perform a bitwise OR with our hardware interrupt flags (`r2`). This effectively applies a "VBlank Stamp" (`0x0001`) onto the BIOS flag.
4. **`strh r3, [r1]`**: We save the stamped flag back to `0x03007FF8`.
5. **`bx lr` (Branch and Exchange)**: The BIOS stored its return address in the Link Register (`lr`) before calling us. This acts as a `return` statement, handing control back to the BIOS IRQ Dispatcher.

### 4. Returning from the BIOS

When the BIOS regains control, it restores the CPU context and exits the interrupt state. The CPU then resumes execution inside the suspended `swi 0x05` BIOS function.

The internal BIOS code for `swi 0x05` looks at `0x03007FF8` (`BIOS_IF`). Because our `irqHandler` stamped the VBlank bit (`0x0001`) into that memory address via the `orr` instruction, the BIOS knows the VBlank condition has been met! (If it wasn't there, the BIOS would assume a different interrupt woke the CPU and would just halt the CPU to sleep again).

Seeing the VBlank condition fulfilled, the BIOS clears the flag and returns control back to our Zig code. Execution jumps out of `waitForVBlank()`, and our game loop proceeds to draw the next frame perfectly synchronized with the hardware!
