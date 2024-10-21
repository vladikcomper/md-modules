
# MD Debugger Macros Reference

This document covers the essential Debugger's API, which is presented in form of macros you can use.

## Table of contents

- [`assert`](#assert)
- [`RaiseError`](#raiseerror)
- [`Console` macros](#console-macros)
  - [`Console.Run`](#consolerun)
  - [`Console.Write`](#consolewrite-and-consolewriteline)
  - [`Console.WriteLine`](#consolewrite-and-consolewriteline)
  - [`Console.SetXY`](#consolesetxy)
  - [`Console.BreakLine`](#consolebreakline)
  - [`Console.Clear`](#consoleclear)
  - [`Console.Sleep`](#consolesleep)
  - [`Console.Pause`](#consolepause)
- [`KDebug` macros](#kdebug-macros)
  - [`KDebug.Write`](#kdebugwriteline-and-kdebugwrite)
  - [`KDebug.WriteLine`](#kdebugwriteline-and-kdebugwrite)
  - [`KDebug.BreakLine`](#kdebugbreakline)
  - [`KDebug.BreakPoint`](#kdebugbreakpoint)
  - [`KDebug.StartTimer`](#kdebugstarttimer-and-kdebugendtimer)
  - [`KDebug.EndTimer`](#kdebugstarttimer-and-kdebugendtimer)
- [Shadow macros](#shadow-macros)

## `assert`

**Added in version 2.5**

**Syntax:**

```m68k
        assert[.b|.w|.l]    src_operand, condition[, dest_operand, debugger]
```

**Description:**

Asserts that the given condition is true. Raises an "assertion failed" exception otherwise with the text of a failed condition.

This only works in DEBUG builds (when `__DEBUG__` symbol is defined). In RELEASE builds, `assert` pseudo-instructions aren't assembled.

Think of assertions as pseudo-instructions for debugging purposes that: test the given operands (`src_operand` and `dest_operand`), continue program execution if `condition` is true, raise an exception with `RaiseError` otherwise. Consider the following example:

```m68k
        assert.w d0, lt, #64       ; assert than `d0` register is less than 64
```

This code is equivalent to the following:

```m68k
        cmp.w    #64, d0
        blt.s    ok
        RaiseError "Assertion failed!"
    ok:
```

Assertions also have a single-operand form for simplicity:

```m68k
        assert.b MyRAMFlag, ne     ; assert that `MyRAMFlag` is not equal to zero
```

Which is the same as using `tst` instead of `cmp` in the equivalent code:

```m68k
        tst.b    MyRAMFlag
        bne.s    ok
        RaiseError "Assertion failed!"
    ok:
```

Operands in assertions can use all the addressing modes that `tst` and `cmp` instructions support:

```m68k
        assert.b (a0), eq            ; assert that the byte at `(a0)` is zero
        assert.w d2, lo, 2(a3)       ; assert that `d2` register is lower than `2(a3)`
        assert.l ($FFFFA000).w, mi   ; assert that the longword at `($FFFFA000).w` is negative
```

**Arguments:**

* `src_operand` - source operand.
* `condition` - condition to test (e.g. `eq`, `ne`, `mi`, `pl`, `cs`, `cc`, `hi`, `hs`, `lo`, `ls`, `gt`, `ge`, `lt`, `le`, `vs`, `vc` etc).
* `dest_operand` (optional) - destination operand; if present, `src_operand` is compared to `dest_operand`, otherwise a single `src_operand` is tested.
* `debugger` (optional) - label of the console program (subroutine) used to print error screen body if assertion fails; if omitted, standard error handler is used (*added in version 2.6*)


## `RaiseError`

**Syntax:**

```m68k
        RaiseError message[, debugger]
```

**Description:**

Displays an error screen with the specified message. Program execution is then halted.

```m68k
        RaiseError "This function isn't implemented yet!"
```

The optional second argument may specify a custom debugger to use. Debugger is a console program which uses `Console` macros to render debug output on the screen and ends with an `rts` instruction (you may also call it outside of exception using `Console.Run`):

```m68k
        RaiseError "Bad pointer: %<.l a0 sym>!", Debugger_AddressRegisters
```

If `debugger` is not specified, the standard program is used which displays CPU registers and stack contents.

**Arguments:**

* `message` - a [formatted string](Formatted_strings.md) representing an error message, for example: `"Object at address %<.w a0 hex> crashed"`; displays in error screen's header.
* `debugger` (optional) - label of the console program (subroutine) used to print error screen body; if omitted, standard error handler is used.

## `Console` macros

This set of macros provides an API for Debugger's built-in console. They are meant to be used inside _console programs_.

Console programs work like normal assembly subroutines, but can call `Console` macros to render debug output on screen. They should end with an `rts` instruction like every standard subroutine:

```m68k
        Console.Run MyConsoleProgram

MyConsoleProgram:
        Console.WriteLine "Hello, world!"
        rts
````

In context of MD Debugger, console program usually print useful debug information and hence are called *debuggers*.

There are several ways to call/specify a _console program_ by its label:

- Using `Console.Run ProgramLabel`;
- By mapping it to joypad buttons on exception screen (see `DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER` in `Debugger.asm`);
- As a third argument in `assert` (e.g. `assert.w d7, ne, #0, ProgramLabel`);
- As a second argument in `RaiseError` (e.g. `RaiseError "Some error!", ProgramLabel`).

> [!NOTE]
>
> If you use `Console` macros outside of a console program, nothing bad happens as the output is suppressed. So there are no side effects, except for wasted CPU cycles. This means you can insert `Console.Write/.WriteLine` statements in subroutines that can be used called both inside and outside of the console.

## `Console.Run`

**Syntax:**

```m68k
        Console.Run program
```

**Description:**

Halts normal execution, initializes a console and runs a specified program/subroutine inside it.

_Console programs_ are essentially subroutines written in assembly, which can also call "high-level" `Console` macros to render debug output on screen. They should end with an `rts` instruction like every standard subroutine.

```m68k
        Console.Run MyConsoleProgram

MyConsoleProgram:
        Console.WriteLine "Player X-position is %<.w objPlayer+xpos>!"
        Console.WriteLine "Player Y-position is %<.w objPlayer+ypos>!"
        rts
```

**Arguments:**

* `program` - a label of the program to run.


## `Console.Write` and `Console.WriteLine`

**Syntax:**

```m68k
        Console.Write text
        Console.WriteLine text
```

**Description:**

Writes a [_formatted string_](Formatted_strings.md) in the console.

`.WriteLine` variant automatically adds a newline at the end of the string.

`.Write` variant doesn't add newline, so the next write will append to the same line. However, you can use `%<endl>` token in string to add newlines manually, for instance:

```m68k
        Console.WriteLine "Hello, world!"
        Console.Write "Ready...%<endl>Set...%<endl>Go!%<endl>"
        Console.WriteLine "d0 is %<.w d0>!"
```

**Arguments:**

* `text` - a formatted string to write in the console.

## `Console.SetXY`

**Added in version 2.5**

**Syntax:**

```m68k
        Console.SetXY  x, y
```

**Description:**

Sets write position to the specified position of screen (in tiles), for example:

```m68k
        Console.SetXY #1, #2
```

Console size is 40 x 28 tiles.

To set the leftmost position, use:

```m68k
        Console.SetXY #0, #0
```

Since `x` and `y` are word-sized _operands_, all M68K addressing modes may be used to pass these parameters, for instance:

```m68k
        Console.SetXY d0, 2(a0)  ; read X from d0, read Y from 2(a0)
```

In ASM68K and AXM68K versions, all M68K addressing modes are supported, but for indexed modes (e.g. `d8(an,dn)`) you need to put the entire operand in brackets so assembler won't confuse a comma inside it for argument separator:

```m68k
        Console.SetXY 2(a0), <YPosTable(pc,d0.w)>  ; add `<...>` around operands with commas!
```

Advanced addressing modes aren't supported in the AS version.

**Arguments:**

* `x` - a word-sized operand (register, memory or immediate value), represents x position in tiles
* `y` - a word-sized operand (register, memory or immediate value), represents y position in tiles


## `Console.BreakLine`

**Syntax:**

```m68k
        Console.BreakLine
```

**Description:**

Adds a newline.

**Alternative:**

```m68k
        Console.Write "%<endl>"
```

## `Console.Clear`

**Syntax:**

```m68k
        Console.Clear
```

**Description:**

Clears the entire console screen and resets the cursor back to the top-left corner (coordinate `#0, #0`).

## `Console.Sleep`

**Added in version 2.5**

**Syntax:**

```m68k
        Console.Sleep  frames
```

**Description:**

Pauses program execution for the given number of frames. The following example pauses for 60 frames (1 second in NTSC mode):

```m68k
        Console.Sleep  #60
```

Since `frames` argument is an operand, it can use different M68K addressing modes, not just _immediate value_ (i.e. `#<Number>`), for instance:

```m68k
        Console.Sleep  d0   ; sleep for the number of frames specified in the d0 register
```

In ASM68K and AXM68K versions, all main M68K addressing modes are supported (same as MOVE instruction), but for indexed modes (e.g. `d8(an,dn)`) you need to put the entire operand in brackets so assembler won't confuse a comma inside it for argument separator:

```m68k
        Console.Sleep <SleepLUT(pc,d0.w)> ; add `<...>` around operands with commas!
```

Advanced addressing modes aren't supported in the AS version.

**Arguments:**

* `frames` - a word-sized operand (register, memory or immediate value), number of frames to sleep.

## `Console.Pause`

**Added in version 2.5**

**Syntax:**

```m68k
        Console.Pause
```

**Description:**

Pauses console program execution until A, B, C or Start button is pressed on the joypad.

## `KDebug` macros

**Added in version 2.5**

This set of macros provides a convenient interface for debug logging, timing code and breakpoints in emulators that support KMod debug registers.

Currently, the only emulators to support KDebug are:
- Blastem-nightly;
- Clowmdemu since v0.8 (limited support);
- Gens KMod (outdated, not recommended).

**`KDebug` macros are only compiled in DEBUG builds (when `__DEBUG__` equate is set).** On unsupported emulators and the real hardware, these macros have no effect either way.

Under the hood, `KDebug` macros communicate with the emulator via unused VDP registers. This, lucky enough, has no side effects on the real hardware. But be careful when using it in the middle of the code that writes to VDP data port for that very reason: `KDebug` resets the last VDP access address. **This is a hardware quirk.**

> [!NOTE]
>
> Since **version 2.6**, you can also use KDebug macros in console programs.

> [!WARNING]
>
> Avoid using `KDebug` macros _in-between_ VDP data port writes. Since `KDebug` integration accesses its own VDP registers, this resets the last write address, so your writes may be disrupted. However, if you explicitly set VDP write address after using `KDebug`, everything will be fine. This is what `Console.Write` does for `KDebug` and `Console` interoperability.

## `KDebug.WriteLine` and `KDebug.Write`

**Added in version 2.5**

**Syntax:**

```m68k
        KDebug.Write text
        KDebug.WriteLine text
```

**Description:**

In DEBUG builds, writes a [_formatted string_](Formatted_strings.md) in the supported emulator's debug window/console. It has no effect on unsupported emulators, on the real hardware and in RELEASE builds.

For logging, `KDebug.WriteLine` has the same interface as `Console.WriteLine`, but writes text to emulator's debug logger window/console instead. It's meant to be used outside of exceptions/console programs.

Unlike `Console.Write`, `KDebug.Write` doesn't output the buffer unless end of the line character (`%<endl>`) is encountered. This is emulator's quirk and cannot be changed. **Always prefer `KDebug.WriteLine` where possible**, because it ends the line for you and the message is displayed immediately.

> [!WARNING]
>
> When using multiple `KDebug.Write` invocations to accumulate a line from several pieces/parts, never forget to put `%<endl>` in the last `.Write` or change it to `.WriteLine`. Your line won't be flushed into emulator's console unless `%<endl>` is sent.

Unlike `Console.Write`/`.WriteLine`, `KDebug.Write`/`.WriteLine` don't support any special formatting tokens except for `%<endl>`. Any tokens like `%<pal0>`, `%<cr>` are ignored.

## `KDebug.BreakLine`

**Added in version 2.5**

**Syntax:**

```m68k
        KDebug.BreakLine
```

**Description:**

In DEBUG builds, flushes the message to supported emulator's debug window/console.

**Alternative:**

```m68k
        KDebug.Write "%<endl>"
```

## `KDebug.StartTimer` and `KDebug.EndTimer`

**Added in version 2.5**

**Syntax:**

```m68k
        KDebug.StartTimer
        KDebug.EndTimer
```

**Description:**

In DEBUG builds, `KDebug.StartTimer` starts counting CPU cycles and `KDebug.EndTimer` displays the number of elapsed cycles. Use it to measure the performance of your code.

Cycle count is displayed in supported emulator's debug window/console. This has no effect on unsupported emulators, on the real hardware and in RELEASE builds.

> [!WARNING]
>
> Out of the supported emulators, Gens KMod and Blastem-nightly seem to calculate cycles differently. **Always prefer Blastem-nightly.**

## `KDebug.BreakPoint`

**Added in version 2.5**

**Syntax:**

```m68k
        KDebug.BreakPoint
```

**Description:**

In DEBUG builds, `KDebug.BreakPoint` is used to set a hard breakpoint anywhere in your code. This pauses program execution and allows you to use emulator's own debugger.

This has no effect in unsupported emulators, on the real hardware and in RELEASE builds.

## Shadow macros

**Added in version 2.6**

Shadow macros are intended for advanced users that want to take advantage of optimizations in some scenarios.

Almost all MD Debugger macros are designed to be completely side-effect free and always backup and restore SR (and CCR) after execution by generating `move.w sr,-(sp)` and `move.w (sp)+,sr` instructions around the actual macros code.

"Shadow" versions remove these safety instructions on assumption that user don't care about original CCR value being lost after macro execution.

> [!WARNING]
>
> Don't use shadow macros unless you know what you're doing! Normal macros are preferable in most scenarios, because debug-only code generally should be reliable, not optimal.

The following shadow macros exist:
- **`_assert`**
- **`_Console.*`** (e.g. `_Console.WriteLine`, `_Console.SetXY` etc);
- **`_KDebug.*`** (e.g. `_KDebug.WriteLine`, `_KDebug.StartTimer` etc);
