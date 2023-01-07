
# MD-Shell

MD-Shell is a stand-alone easy to use "assembly header" running small programs as Sega Mega-Drive ROMs.

It includes initialization code, error handler and all debugger macros (e.g. `Console.Write`, `Console.Run` etc).

## Simple hello-world

Once you include `MDShell.asm` header, you can write a simple console program in 3 lines of code:

```
	include "MDShell.asm"

Main:
	Console.WriteLine "Hello, world!"
	rts
```

Each program should define "Main:" as an entry point.

Anywhere in your code you can access `Console` object and call `RaiseError`.

## Macros reference

### `RaiseError`

**Syntax:**

        RaiseError text[, handler]

**Description:**

Displays an error screen with the specified message. Program execution is then halted.

**Arguments:**

* `text` - a formatted string representing an error message, for example: `"Object at address %<.w a0 hex> crashed"`; displays in error screen's header.
* `handler` (optional) - label of the console program (subroutine) used to print error screen body; if omitted, standard error handler is used.

### `Console.Write` and `Console.WriteLine`

**Syntax:**

        Console.Write text
        Console.WriteLine text

**Description:**

Writes a _formatted string_ in the console.

`.WriteLine` variant automatically adds a newline at the end of the string.

`.Write` variant doesn't add newline, so the next write will append to the same line. However, you can use `%<endl>` token in string to add newlines manually, for instance:

        Console.Write "Ready...%<endl>Set...%<endl>Go!"

**Arguments:**

* `text` - a formatted string to write in the console.


### `Console.SetXY`

**Syntax:**

        Console.SetXY  x, y

**Description:**

Sets write position to the specified position of screen (in tiles), for example:

        Console.SetXY #1, #2

Console size is 40 x 28 tiles.

To set the leftmost position, use:

        Console.SetXY #0, #0

Since `x` and `y` are _operands_, all M68K addressing modes may be used to pass these parameters, for instance:

        Console.SetXY d0, PositionData+1(pc,d1)  ; read X from d0, read Y from PositionData+1(pc,d1)

**Arguments:**

* `x` - operand (register, memory or immediate value), represents x position in tiles
* `y` - operand (register, memory or immediate value), represents y position in tiles


### `Console.BreakLine`

**Syntax:**

        Console.BreakLine

**Description:**

Adds a newline.

**Alternative:** Console.Write "%<endl>"

## Formatted string reference

Formatted strings may include flags or formatted values, which are encapsulated in `"%<...>"`` tokens, for example:

        Console.Write "d0 equals to %<.b d0 hex|signed>, and... %<endl>d1 is %<.w d1>"

**Supported tokens**

    %<endl> - end of line flag, adds a newline;
    %<cr> - carriage return, jump to the beginning of the same line;
    %<pal0> - use palette line #0;
    %<pal1> - use palette line #1;
    %<pal2> - use palette line #2;
    %<pal3> - use palette line #3;
    %<setw,X> - set line width: number of characters before automatic newline
        by default, X=40 in console-only mode, X=38 on error screens
        WARNING! In AS version, you have to write "%<setw>%<X>" due to macros limitations
    %<setx,X> - set X-position of the next character on the line;
        WARNING! In AS version, you have to write "%<setx>%<X>" due to macros limitations

Flags can be merged into a single token, for example: instead of `"%<endl>%<setx,2>%<pal0>"` you can just write `"%<endl,setx,2,pal0>"`.

> **Warning**
>
> Merging flags is only supported in ASM68K version.

**Formatted values tokens:**

`%<type operand[ format]>`

    type - must be .b, .w or .l
    operand - source register or memory address, supports the same addressing modes as MOVE command
    format (optional) - specifies value formatter and it's arguments, if needed. Default format is hex.
        hex - display as hexadecimal number
        dec - display as decimal number
        bin - display as binary number
            hex|signed, dec|signed, bin|signed -- treat value as signed number (additionally displays + or - before the number depending on its sign)
        sym - treat value as offset, decode into symbol+displacement
        str - treat value as offset, display C-string pointered by it

**Examples:**

Displaying numbers:

```asm
    move.w   #$F211, d0
    Console.WriteLine "%<.b d0>"              ; prints "11"
    Console.WriteLine "%<.b d0 dec>"          ; prints "17"
    Console.WriteLine "%<.w d0>"              ; prints "F211"
    Console.WriteLine "%<.w d0 hex|signed>"   ; prints "-0DEF"
    Console.WriteLine "%<.b d0 hex|signed>"   ; prints "+11"
    rts
```

Advanced usage:

```asm
   lea     SomeData, a0
   moveq   #1, d0
 
   Console.WriteLine "a0 = %<.l a0 sym>"       ; prints "a0 = somedata"
   Console.WriteLine "%<.b SomeData(pc,d0)>"   ; prints "19"
   addq.w  #1, d0
   Console.WriteLine "%<.b SomeData(pc,d0)>"   ; prints "B3"

   Console.WriteLine "%<.l #SomeString str>"   ; prints "Apples!"

   rts
 
SomeData:
   dc.b   $AE, $19, $B3, $10
 
SomeString:
   dc.b   "Apples!", 0
```

> **Warning**
>
> Trying to display the value of register SP (also known as A7) or address using it (e.g. %<.l -4(sp)>) leads to unexpected results. This is because formatted strings arguments are stored on stack at run-time, so stack pointer's value is different by the time it's requested.
> 
> Do not try to print SP directly, the results are unreliable.

> **Warning**
> AS version has limitations and only supports register direct, register indirect and absolute addressing modes. Absolute mode is only supported when passing symbols, not raw addresses, e.g.:
>
> `Console.Write "%<.w $FFFFEE00>"` doesn't work in AS, but `Console.Write "%<.w Camera_X_Pos>"` does.
>
> ASM68K version supports all standard addressing modes that M68K provides.