
# Powerful debugging techniques

This guide lists some really powerful debugging techniques that I use personally.

## Validate function input parameters with assertions

Consider you have a function like this one in your code:

```m68k
; INPUT:
;  d0 .w = Transfer size in words minus one
;  a0    = Data pointer
;  a6    = VDP Data Port

TransferDataToVRAM:
	@loop:
		move.w	(a0)+, (a6)
		dbf	d0, @loop
	rts
```

Let's assume this low-level function is used pretty much everywhere and you'd like to be sure its input parameters are set correctly. But you don't want to add actual code to slow down your game.

**Assertions** to the rescue:

```m68k
; INPUT:
;  d0 .w = Transfer size in words minus one
;  a0    = Data pointer
;  a6    = VDP Data Port

TransferDataToVRAM:
	assert.w d0, pl
	assert.l a0, hi, #ROM_Start
	assert.l a0, lo, #ROM_End
	assert.l a6, eq, #VDP_Data_Port

	@loop:
		move.w	(a0)+, (a6)
		dbf	d0, @loop
	rts
```

These extra checks assert the following about your input parameters:
- **d0** is positive, i.e. between `$0000`..`$7FFF`, which doesn't exceed VRAM size;
- **a0** is between `ROM_Start` and `ROM_End`, meaning you transfer data from the ROM section;
- **a6** points to the VDP Data Port.

If any if the checks above fails, you'll see "Assetion failed" exception with the details of the failed condition. You'll know which one failed and where your function was called from to locate the bug quickly.

**Remember that `assert` pseudo-instructions are only complied in DEBUG builds.** This means they create absolutely no overhead for your final code in RELEASE builds, but you need to run DEBUG builds during development to make use of assertions.

## Log in-game events with `KDebug`

Ever dreamt of logging what your game is doing without entering debuggers and halting its execution? With `KDebug` interface the debugger provides and an emulator that supports it, your dreams come true!

The following example shows how you can log any invocation Kosinski decompressor in Sonic 1 and display what art it reads.

Just find `KosDec:` label in your disassembly and insert the following line right after it:

```m68k
KosDec:
	KDebug.WriteLine "KosDec: Decompressing %<.l a0 sym> -> %<.l a1>"
```

Now build your game and run the DEBUG build in Blastem-nightly or Gens KMod. In emulator's debug console you should see the following messages pop up as you play:

```
KDEBUG MESSAGE: KosDec: Decompressing Kos_Z80 -> 00A00000
KDEBUG MESSAGE: KosDec: Decompressing Kos_Z80 -> 00A00000
KDEBUG MESSAGE: KosDec: Decompressing Blk256_GHZ -> 00FF0000
```

## Running arbitrary code in DEBUG builds

While `assert` and `KDebug` macros are limited to DEBUG builds out of the box, sometimes you just need to run your own arbitrary code for more fine-grained debugging. In standard Debugger configuration (granted you followed installation instructions), you can simply do so by checking if `__DEBUG__` symbol is defined.

The syntax for checking it is however different between ASM68K and AS assemblers.

**AS version:**

```m68k
MyHeavyFunction:
	ifdef __DEBUG__
		tst.w 	d0
		beq.s 	DebugOnlyError
		jsr	SomeOtherDebugFunction
	endif

	move.w 	d0, (a0)+
	move.w 	d1, (a0)+
	move.w 	d2, (a0)+
	move.w 	d3, (a0)+
	: <...>
```

**ASM68K version:**

```m68k
MyHeavyFunction:
	if def(__DEBUG__)
		tst.w 	d0
		beq.s 	DebugOnlyError
		jsr	SomeOtherDebugFunction
	endif

	move.w 	d0, (a0)+
	move.w 	d1, (a0)+
	move.w 	d2, (a0)+
	move.w 	d3, (a0)+
	: <...>
```

## Measuring function's performance with `KDebug`

In DEBUG builds, you can roughly measure number of cycles a call of any function takes using `KDebug.StartTimer` and `KDebug.EndTimer`.

> [!WARNING]
>
> This recipe only properly works in Blastem-nightly!

Consider the following example:

```m68k
	KDebug.WriteLine "Starting to measure performance of SomeHeavyFunction..."
	KDebug.StartTimer
	jsr	SomeHeavyFunction
	KDebug.EndTimer 	; this will print number of cycles measured
```

Bear in mind:

- This method has a small error margin: the measured cycles include overhead of calling `.StartTimer`, `.EndTimer` on its own;
- `KDebug` only works in DEBUG builds;
- Use Blastem-nightly to get accurate results.

## Debugging functions inside `Console`

If you need to debug just one function invocation, you can wrap it into a console program.

Consider the following function:

```m68k
MyHeavyFunction:
	move.w 	d0, (a0)+
	move.w 	d1, (a0)+
	move.w 	d2, (a0)+
	move.w 	d3, (a0)+
	: <...>
```

Let's wrap it into a console program:

```m68k
MyHeavyFunction:
	Console.Run @self	; .self in AS

@self: ; .self in AS
	move.w 	d0, (a0)+
	Console.WriteLine "Wrote %<.w d0> before the address %<.l a0 sym>"
	move.w 	d1, (a0)+
	Console.WriteLine "Wrote %<.w d1> before the address %<.l a0 sym>"
	move.w 	d2, (a0)+
	Console.WriteLine "Wrote %<.w d2> before the address %<.l a0 sym>"
	move.w 	d3, (a0)+
	Console.WriteLine "Wrote %<.w d3> before the address %<.l a0 sym>"
	: <...>
```

`Console.Run` instantiates a debugger console and allows you to display text with `Console.WriteLine` and other macros.

**Bear in mind that invoking a console effectively halts running of your game.** Once the console program stops (hits `rts`), there's no going back. But it's quite useful if your function runs every frame and you need to debug only a single invocation of it.

But what if you need to debug a specific call of this function? In this case, you probably don't want `Console.Run @self` inside function itself so it doesn't invoke console every time.

You may find a specific call of your function and wrap just it into a `Console.Run` call:

```diff
-	jsr	MyHeavyFunction
+	Console.Run MyHeavyFunction
```

But what happens if `MyHeavyFunction` is called elsewhere and `Console.WriteLine` inside it is executed outside of `Console` interface? **Nothing bad happens**, every `Console.*` call outside of a console environment is just ignored.
