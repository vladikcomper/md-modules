
# MD-Debugger Troubleshooting

## Problem: I can't see any symbols in exceptions, just raw offsets

In 99,99% of cases this means the Debugger is not able to find symbols table because it wasn't included or was placed incorrectly.

**Things to check out:**

- Do you call `convsym` utility in your build scripts? Is it invoked correctly?
- Make sure you don't have anything included after `include "ErrorHandler.asm"` in your code, not even a single byte;
- Make sure you don't pad your ROM **before** appending the symbol table with `convsym`. Remember that the symbol table must be appended directly after the Error Handler (`include "ErrorHandler.asm"`).

## Problem: I use SRAM, my ROM is big and Error Handler seems to glitch out

SRAM starts at offset `$200000`, this is after the second megabyte of your ROM. If SRAM access is enabled, it effectively remaps all the memory accesses after offset `$200000` from ROM to SRAM.

This becomes an issue if your ROM is larger than 2 MiB. Since the error handler and debug symbol table are included at the very end, they are affected first.

You need to enable SRAM access only when you need to write anything to SRAM and disable it right after. If you're unsure, check out how S3K does it in the disassembly: it's 4 MiB game, so it has to be really careful with SRAM access.

## Problem: `assert` and `KDebug` macros have no effect

`assert` and `KDebug` macros are only compiled in DEBUG builds. It's when `__DEBUG__` symbol is defined.

If you followed the installation instructions, you should have two builds of your ROM: RELEASE (`<romname>.bin`) and DEBUG (`<romname>.debug.bin`). `assert` and `KDebug` macros only generate code in DEBUG builds and are just ignored in RELEASE ones.

If you have troubles testing `KDebug` macros in DEBUG builds, make sure you use the supported emulator. See the [Using KDebug integration](Use_KDebug_integration.md) guide.

## Problem: Sometimes when I use `assert` or `KDebug` macros, I get "illegal zero-length branch" errors

This is because `assert` and `KDebug` don't generate any code in RELEASE builds. Consider the following example:

```m68k
MyFunction:
	tst.b	SomeFlag
	beq.s 	@skip
	KDebug.WriteLine "Calling MyFunction when SomeFlag is set!"
@skip:
```

In RELEASE builds (when `__DEBUG__` symbol is not set), the `KDebug.WriteLine` invocation effectively turns into nothing:

```m68k
MyFunction:
	tst.b	SomeFlag
	beq.s 	@skip
@skip:
```

This, in turn, causes assembler to fail with "Illegal zero-length branch" error because `beq.s` cannot jump to the very next line (`beq.w` can, on the other hand).

**The easiest way** to avoid this is to add a dummy `nop` before your macro invocation in this case.

**A proper way** to fix this is to compile the branch itself in DEBUG builds only (if it's only used for debugging):

```m68k
MyFunction:
	if def(__DEBUG__)			; ifdef __DEBUG__ in AS
		tst.b	SomeFlag
		beq.s 	@skip
		KDebug.WriteLine "Calling MyFunction when SomeFlag is set!"
	@skip:
	endif
```

## Problem: Using `KDebug` or `Console` alongside VRAM writes has side effects

Be extremely careful when using `KDebug` or `Console.Write`/`.WriteLine`/`.BreakLine` to debug code that does VRAM/CRAM/VSRAM access. All these macros access VDP, so it resets the last accessed VRAM/CRAM/VSRAM address. Moreover, `Console.Write` calls set last write address to on-screen output so your code may output data to the screen instead of the intended location.

This is a hardware limitation unfortunately, there isn't a universal workaround for this.

To make debugging VDP writes as pain-free as possible, follow this advice:
- Make sure you don't call `KDebug` or `Console` macros in-between VDP data port writes.
- If you absolutely have to, manually set VDP write address after each macro call.
