
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
        Console.Write "d0 equals to %<.b d0 hex|signed>, and... %<endl>d1 is %<.w d1>"
```

There are two types of tokes:

- **Formatted value tokens:** `%<.w d0>`, `%<.l 4(a0) sym>`, `%<.w MyData hex|signed>` etc
- **Output control tokens:** `%<endl>`, `%<pal0>`, `%<setx>%<1>` etc

### Formatted value tokens

**Syntax:**

	%<.b|.w|.l operand[ format]>

**Arguments:**

- `.b`, `.w` or `.l` - determines operand size (byte, word or long respectively);

- `operand` - represents a value to display (register or memory), specify one of addressing mode that M68K supports.
	- __In ASM68K version__, all M68K addressing modes are supported;
	- __In AS version__, only the following modes are supported:
	  - `$1234`, `SymbolOrNumber` - absolute, but `(xxx).w`/`(xxx).l` syntax isn't recognized;
	  - `#1234`, `#SymbolOrNumber` - immediate value;
	  - `d0`-`d7`/`a0`-`a7` - data or address register direct;
	  - `(a0)`-`(a6)` - address register indirect;
	  - `number(an)` - address register indirect with displacement;
	  - `SymbolOrNumber(pc)` - PC-relative.

- `format` (optional) - value format specifier; `hex` is used by default. The following formats are supported:
	- `hex`, `hex|signed` - display as a hexadecimal number (unsigned or signed);
	- `dec`, `dec|signed` - display as a decimal number (unsigned or signed);
		- **Note:** For AXM68K assembler, it's `deci` instead, because of a name conflict.
	- `bin`, `bin|signed` - display as a binary number (unsigned or signed);
	- `sym` - treat value as an offset, display as `symbol+displacement`;
	- `str` - treat value as an offset, display null terminated C-string it points to.

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
	- __In AS version__, the syntax is `%<setw>%<W>` due to macros limitations.
- `%<setx,X>` - set X-position of the next character on the line;
	- __In AS version__, the syntax is `%<setx>%<X>` due to macros limitations.

__In ASM68K version__, flags can be merged into a single token, for example: instead of `"%<endl>%<setx,2>%<pal0>"` you can just write `"%<endl,setx,2,pal0>"` (this also applied to AXM68K).
