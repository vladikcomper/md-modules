
# MD Shell Formatted Strings Reference

MD Shell comes with its own powerful formatted strings syntax.

Every macro that you can pass a string/message to supports this syntax and allows you to format text and display various arguments.

The following macros use formatted strings:

- `__ErrorMessage`
- `RaiseError`
- `Console.Write`
- `Console.WriteLine`
- `KDebug.Write`*
- `KDebug.WriteLine`*

*) `KDebug.Write`/`.WriteLine` don't support most of the output control tokens, except for `%<endl>` (note that all formatted value tokens are fully supported).

## Tokens in formatted strings

Formatted strings may include flags or formatted values, which are encapsulated in `%<...>` tokens, for example:

```m68k
        Console.WriteLine "d0 equals to %<.b d0 hex|signed>, and... %<endl>d1 is %<.w d1>"
        Console.WriteLine "%<pal1>a0 points to %<.l a0 sym>"
        Console.WriteLine "MyMemoryFlag is set to %<.b MyMemoryFlag>!"
```

There are two types of tokes:

- **Formatted value tokens:** `%<.w d0>`, `%<.l 4(a0) sym>`, `%<.w MyData hex|signed>` etc;
- **Output control tokens:** `%<endl>`, `%<pal0>`, `%<setx>%<1>` etc.

### Formatted value tokens

**Syntax:**

	%<.size operand[ format]>

**Arguments:**

- `.size` - determines operand size, can be one of `.b`, `.w` or `.l` (byte, word or long respectively);

- `operand` - represents a value to display (register or memory), specify one of addressing mode that M68K supports.
	- __In ASM68K projects__, all M68K addressing modes are supported (same applies to AXM68K bundles);
	- __In AS projects__, only the following modes are supported:
	  - `$1234`, `SymbolOrExpression`, `(SymbolOrExpression).w`, `(SymbolOrExpression).l` - absolute;
	  - `#1234`, `#SymbolOrExpression` - immediate value;
	  - `d0`-`d7`/`a0`-`a7` - data or address register direct;
	  - `(a0)`-`(a6)` - address register indirect;
	  - `$1234(an)`, `SymbolOrExpression(an)` - address register indirect with displacement;
	  - `$1234(pc)`, `SymbolOrExpression(pc)` - PC-relative.

- `format` (optional) - value format specifier; `hex` is used by default. The following formats are supported:
	- `hex`, `hex|signed` - display as a hexadecimal number (unsigned or signed);
	- `dec`, `dec|signed` - display as a decimal number (unsigned or signed);
		- **Note:** For AXM68K assembler, it's `deci` instead, because `dec` is a Z80 instruction.
	- `bin`, `bin|signed` - display as a binary number (unsigned or signed);
	- `sym`, `sym|forced`, `sym|split` - treat value as a memory pointer, display as `symbol+displacement` (where `symbol` is the nearest symbol before the pointer, if available);
		- If the raw value is `$FF001C` and the nearest symbol before it is `RAM_Start = $FF0000`, it'll display `RAM_Start+$1C`;
		- Is nearest symbol isn't found or symbol table isn't available, it will draw raw value instead (e.g. `FF001C` for the example above);
		- `sym|forced` forces to display `<unknown>` instead of a raw value if symbol was not found (useful if you've already drawn full offset before so you don't repeat yourself);
		- `sym|split` displays the nearest symbol only, ignoring the displacement, if any (e.g. `RAM_Start` instead of `RAM_Start+$1C` for the example above); if symbol wasn't found, displays the raw value or `<undefined>` if you use `sym|split|forced`;
		- `sym|split|forced` then `disp|weak` can be used if you need to format symbol name and displacement separately, e.g.: `"%<.l myPointer sym|split|forced>%<pal2>%<disp|weak>"`.
	- `str` - treat value as a pointer to a null-terminated string (C-style string).

**Examples:**

Displaying numbers:

```m68k
	Console.Run MyConsoleProgram

MyConsoleProgram:
    move.w   #$F211, d0
    Console.WriteLine "%<.b d0>"              ; prints "11"
    Console.WriteLine "%<.b d0 dec>"          ; prints "17"
    Console.WriteLine "%<.w d0>"              ; prints "F211"
    Console.WriteLine "%<.w d0 hex|signed>"   ; prints "-0DEF"
    Console.WriteLine "%<.b d0 hex|signed>"   ; prints "+11"
    rts
```

Advanced usage:

```m68k
	Console.Run MyConsoleProgram

MyConsoleProgram:
   lea     SomeData, a0
   moveq   #1, d0
 
   Console.WriteLine "a0 = %<.l a0 sym>"       ; prints "a0 = SomeData"
   Console.WriteLine "%<.b SomeData(pc,d0)>"   ; prints "19" (ASM68K only)
   addq.w  #1, d0
   Console.WriteLine "%<.b SomeData(pc,d0)>"   ; prints "B3" (ASM68K only)

   Console.WriteLine "%<.l #SomeString str>"   ; prints "Apples!"
   rts
 
SomeData:
   dc.b   $AE, $19, $B3, $10
 
SomeString:
   dc.b   "Apples!", 0
```

### Output control tokens

**Token list:**

- `%<endl>` - a end-of-line flag, adds a newline;
- `%<cr>` - a carriage return flag, jumps to the beginning of the same line;
- `%<pal0>` - use palette line #0 (white);
- `%<pal1>` - use palette line #1 (yellow);
- `%<pal2>` - use palette line #2 (blue);
- `%<pal3>` - use palette line #3 (dark-blue);
- `%<setw,W>` - set line width: number of characters before an automatic newline;
	- by default, W=40 in console-only mode, W=38 on error screens
	- __In AS projects__, the syntax is `%<setw>%<W>` due to macros limitations.
- `%<setx,X>` - set X-position of the next character on the line;
	- __In AS projects__, the syntax is `%<setx>%<X>` due to macros limitations.

__In ASM68K projects__, flags can be merged into a single token, for example: instead of `"%<endl>%<setx,2>%<pal0>"` you can just write `"%<endl,setx,2,pal0>"`.
