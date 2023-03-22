
# ConvSym - Symbol extraction and conversion utility

**ConvSym** is a command-line utility aimed to extract symbol lists from various assembler-specific file formats and convert them into DEB1/DEB2 formats supported by the "Advanced Error Handler and Debugger" or human-readable plain-text files.

It was originally designed to be used with the **ASM68K** and **The Macroassembler AS** assemblers, however, ConvSym's high configurability makes it possible to use with other tools and environments, including SGDK (although those may not be fully supported by the "Advanced Error Handler and Debugger").

The utility supports various input and output processing and transformation options, allowing for a high level of flexibility.

## Table of contents

* [Usage](#usage)
  * [Supported options](#supported-options)
  * [Examples](#examples)
* [Converting SGDK symbols](#converting-sgdk-symbols)
* [Input formats parsers](#input-formats-parsers)
  * [`asm68k_sym` parser](#asm68k_sym-parser)
  * [`asm68k_lst` parser](#asm68k_lst-parser)
  * [`as_lst` parser](#as_lst-parser)
  * [`as_lst_exp` parser](#as_lst_exp-parser)
  * [`log` parser](#log-input-parser)
* [Output formats parsers](#output-formats-parsers)
  * [`deb2` parser](#deb2-output-parser)
  * [`deb1` parser](#deb1-output-parser)
  * [`asm` parser](#asm-output-parser)
  * [`log` parser](#log-output-parser)
* [Version history](#version-history)

## Usage

**ConvSym** uses the following command-line arguments format:

	convsym [input_file|-] [output_file|-] <options>

*Input* and *output files* are mandatory arguments. When run without arguments, options summary is displayed.

When using `-` as input and/or output file name, the I/O is redirected to STDIN and/or STDOUT respectively.

### Supported options

```
  -in [format]
  -input [format]
    Selects input file format. Supported formats: asm68k_sym, asm68k_lst,
    as_lst, as_lst_exp, log
    Default: asm68k_sym

  -out [format]
  -output [format]
    Selects output file format. Supported formats: asm, deb1, deb2, log
    Default: deb2

  -inopt [options]
    Additional options specific for the input parser.

  -outopt [options]
    Additional options specific for the output parser.

Offsets conversion options:
  -base [offset]
    Sets the base offset for the input data: it is subtracted from every 
    symbol's offset found in [input_file] to form the final offset.
    Default: 0

  -mask [offset]
    Sets the mask for the offsets in the input data: it's applied to every 
    offset found in [input_file] after the base offset subtraction (if occurs).
    Default: FFFFFF

  -range [bottom] [upper]
    Determines the range for offsets allowed in a final symbol file (after 
    subtraction of the base offset).
    Default: 0 3FFFFF

  -a
    Enables "Append mode": symbol data is appended to the end of the 
    [output_file]. Data overwrites file contents by default.
    This is usually used to append symbols to ROMs.

  -noalign
    Don't align symbol data in "Append mode", which is aligned to nearest
    even offset by default. Using this option is not recommended, it's only 
    there to retain compatilibity with older ConvSym versions.

Symbol table dump options:
  -org [offset]
    If set, symbol data will placed at the specified [offset] in the output 
    file. This option cannot be used in "append mode".

  -ref [offset]
    If set, a 32-bit Big Endian offset pointing to the beginning of symbol
    data will be written at specified offset. This is can be used, 
    if symbol data pointer must be written somewhere in the ROM header.

Symbols conversion and filtering options:
  -toupper
    Converts all symbol names to uppercase.

  -tolower
    Converts all symbol names to lowercase.

  -filter [regex]
    Enables filtering of the symbol list fetched from the [input_file]
    based on a regular expression.

  -exclude
    If set, filter works in "exclude mode": all labels that DO match
    the -filter regex are removed from the list, everything else stays.
```

### Examples

Convert listing file `listing.lst` in `as_lst` format to `symbols.log` of `log` format:

```sh
convsym listing.lst symbols.log -input as_lst -output log
```

Convert listing file `listing.lst` in `as_lst` format to `deb2` format and append to the end of `rom.bin` file:

```sh
convsym listing.lst rom.bin -input as_lst -output deb2 -a
```

## Converting SGDK symbols

> **Warning**
> 
> SGDK isn't officially supported by the "Advanced Error Handler and Debugger", which makes use of the converted symbols, hence no installation instructions are provided.
> At this point, you'll have to figure out installation on your own.

While **ConvSym** doesn't support SGDK, it's still possible to feed it the symbol list and generate debug symbols database for the "Advanced Error Handler and Debugger".

Since **version 2.1**, ConvSym supports `log` input parser, so you can build symbols database from any source as long as you're able to represent symbol lists in a simple plain text format: each line must contain symbol name, followed by ":" character (separator) and symbol's hexadecimal offset (you can also use a different separator, see `log` parser documentation below for more information). For example:

```
SomeSymbol: 0
AnotherSymbol: 1C0
Symbol2000: 420C
```

On Linux, it's possible to use `nm` utility to list symbols from the ELF binary that SGDK build produces, pipe it to `awk` to alter lines format and the pipe the results to `convsym`.

Consider the following example:

```
nm -n out/rom.out | awk '{print $1":",$3}' | ./convsym - out/rom.deb2 -in log
```

This will extract symbols from `out/rom.out` and convert them to `out/rom.deb2` (DEB2 database format for the "Advanced Error Handler and Debugger").

Alternatively, using the `-a` flag, you can append symbols to your ROM instead. For this to work properly, make sure ROM is rebuilt every time `convsym` is called (otherwise, after several invocations, you'll accumulate more than one symbols table at the end of ROM):

```
nm -n out/rom.out | awk '{print $1":",$3}' | ./convsym - out/rom.bin -in log -a
```


## Input formats parsers

Summary of currently supported input formats and their respective parsers (input data format can be specified via `-input` option, or its shorthand: `-in`):

* `asm68k_sym`, `asm68k_lst` - **ASM68K** assembler symbol and listing files;
* `as_lst`, `as_lst_exp` - **The AS Macro Assembler** listing files (*stable* since **version 2.8**, and *experimental*);
* `log` - Plain-text symbol tables (since **version 2.1**).

Some parsers support additional options, which can be specified via `-inopt` option. These options are described below.

### `asm68k_sym` parser

This parser expects a symbol file produced by the **ASM68K** assembler for input. It's the recommended parser for projects using **ASM68K**.

It also supports local symbols, if produced by the assembler.

> **Note**
> 
> In order to include local labels in the symbol file, `/v+` assembly option should be used.

**Options:**

Since **version 2.6**, this parser supports the following options:

```
  /localSign=[x]
    determines character used to specify local labels

  /localJoin=[x]
    character used to join local label and its global "parent"

  /processLocals[+|-]
    specify whether local labels will processed (if not, the above
    options have no effect)
```

Default parser options can be expressed as follows:

	-inopt "/localSign=@ /localJoin=. /processLocals+"

### `asm68k_lst` parser

This parser expects a listing file produced by the **ASM68K** assembler for input. Local symbols are also supported by default.

> **Note**
>
> In order for some macro-related parsing options to work correctly, `/m` argument should be used on the assembler side to properly expand macros in the listing file (please consult the assembler manual for more information).

**Known issues**:

* The parser will ignore line break character `&`, as line continuations aren't properly listed by the **ASM68K** assembler; some information may be lost.
* Labels before the `if` directive (and its derivatives) may not be included in the listing file due to the assembler bug, hence they will be missing from the symbols table generated by **ConvSym**.
* Parser doesn't tolerate `SECTION` directives in the listing files, as assembler generates incorrect offsets whenever they are used; expect a lot of missing or misplaced symbols if you use them. The fix for this cannot be provided in the current implementation of the parser.

**Options:**

```
  /localSign=[x]
    determines character used to specify local labels; default: @

  /localJoin=[x]
    character used to join local label and its global "parent"; default: .

  /ignoreMacroDefs[+|-]
    specify whether macro definitions listings should be ignored (lines between
    "macro" and "endm"); default: +

  /ignoreMacroExp[+|-]
    specify if lines representing macro expansions should be ignored; default: -

  /addMacrosAsOpcodes[+|-]
    set if macros that process label as parameter (defined as "macro *") should 
    be recognized when used; default: +

  /processLocals[+|-]
    specify whether local labels will processed; default: +
```

Default parser options can be expressed as follows:

	-inopt "/localSign=@ /localJoin=. /ignoreMacroDefs+ /ignoreMacroExp- /addMacrosAsOpcodes+ /processLocals+"


### `as_lst` parser

This parser expects a listing file produced by the **AS** assembler for input. It's the recommended parser for projects using **AS**.

Since version **version 2.8**, it works by processing a symbol table at the end of the file. This parser superseded the old experimental one, which is now available as `as_lst_exp` (so if you're looking for pre-v2.8 behaviour for some reason, use that instead).

It also supports local symbols, if produced by the assembler.

**Known issues**:

* Sonic 2 and Sonic 3K disassemly also compile the Z80 driver in the same project using `org`/`phase` to locate Z80-related labels starting from offset $000000. This causes Z80 and M68K symbols to be interleaved, thus messing up the symbol table for up to the first 8 kb of ROM data. There's no clean way to get rid of conflicting labels, but thankfully the disassemblies have most of Z80-labels start with the letter `z`, so you can add the following command-line options to filter them out: `-exclude -filter "z.+"'`

**Options:**

Since **version 2.8**, this parser supports the following options:

```
  /localJoin=[x]
    character used to join local label and its global "parent"

  /processLocals[+|-]
    specify whether local labels will processed (if not, the above
    options have no effect)

  /ignoreInternalSymbols[+|-]
    whether to ignore internal symbols (e.g. `__FORW123`) generated by AS in 
    place of nameless labels (+, - etc)
```

Default parser options can be expressed as follows:

	-inopt "/localJoin=. /processLocals+ /ignoreInternalSymbols+"


### `as_lst_exp` parser

*This parser is available since **version 2.8**.*

This is an experimental version of listing files parser for the AS assembler. Like `as_lst` parser, it expects a listing file produced by the **AS** assembler for input. 

Using this parser is currently not recommended and its implementation may drastically change in future versions of ConvSym.

Before **version 2.8** it was actually in place of the `as_lst` parser, but the latter has since been replaced with a more stable and refined implementation.


### `log` input parser

*This parser is available since **version 2.1**.*

This parser expects a plain-text file, where each row logs an individual symbol name and its offset, in order.

The default format is the following:

```
[HexOffset]: [SymbolName]
```

Whitespaces and tabulation are ignored and don't affect parsing.

**Options:**

```
  /separator=[x]
    determines character that separates labes and offsets, default: ":"

  /useDecimal[+|-]
    sets whether offsets should be parsed as decimal numbers; default: -
```

Default parser options can be expressed as follows:

	-inopt "/separator=: /useDecimal-"


## Output formats parsers

Summary of currently supported output formats and their respective parsers (output data format can be specified via `-output` option, or its shorthand: `-out`):

* `deb2` - Debug symbols database format for "The Advanced Error Handler and Debugger 2.x";
* `deb1` - Debug symbols database format for "The Advanced Error Handler and Debugger 1.x";
* `asm`, `log` - Plain-text **.asm** and **.log**/**.txt** files.

Some parsers support additional options, which can be specified via `-outopt` option. These options are described below.

### `deb2` output parser

This parser outputs debug symbols database in DEB2 format, which is the format supported by the "The Advanced Error Handler and Debugger". This is the default output parser.

**Options:**

Since **version 2.7**, this parser supports the following options:

```
  /favorLastLabels[+|-]
    sets whether to prefer the last processed label when multiple labels share 
    the same offset (the first processed label is chosen otherwise); default: -
```

Default parser options can be expressed as follows:

	-outopt "/favorLastLabels-"

### `deb1` output parser

This parser outputs debug symbols database in old DEB1 format. This is an outdated and limited format which is not supported by the current version of "The Advanced Error Handler and Debugger". This parser only aims to retain compatibility with the Error Handler 1.0.

**Options:**

Since **version 2.7**, this parser supports the following options:

```
  /favorLastLabels[+|-]
    sets whether to prefer the last processed label when multiple labels share 
    the same offset (the first processed label is chosen otherwise); default: -
```

Default parser options can be expressed as follows:

	-outopt "/favorLastLabels-"


### `asm` output parser

By default, this parser produces a symbol list in assembly format recognized by both **ASM68K** and **AS** assemblers.

The default format is the following:

```
[SymbolName]:	equ	$[HexOffset]
```

This format can be altered by passing **printf**-compatible format string, where the first argument corresponds to the symbol name and the second corresponds to the offset.

Default parser options can be expressed as follows:

	-outopt "%s:	equ	$%X"

### `log` output parser

By default, this parser produces symbol list in plain-text format that is compatible with the input parser of the same name (see "`log` input parser").

The default format is the following:

```
[HexOffset]: [SymbolName]
```

This format can be altered by passing **printf**-compatible format string, where the first argument corresponds to the symbol name and the second corresponds to the offset.

Default parser options can be expressed as follows:

	-outopt "%X: %s"


## Version history

### Version 2.9.1 (2023-03-22)

* `asm68k_sym` parser:
  - Fixed incorrect behavior of `/processLocals-` option switch, if local labels were present in the symbol file. ConvSym would just add local labels in raw unprocessed form (e.g. `@local`, not `globalParent.local`) instead of ignoring them.

### Version 2.9 (2023-01-05)

* When appending symbol data to the of ROM (when using `-a` flag), ConvSym now auto-aligns it on the even offset;
* `-noalign` option was added to force the old behavior (don't align on append).

* `asm68k_lst` parser:
  - Fixed missing support for multiple labels (symbols) on the same offset.

### Version 2.8 (2022-12-28)

* Completely overhauled `as_lst` parser; it's now stable and "Production-ready".
* The old experimental parser is still available as `as_lst_exp`;
* Improved built-in help (displayed in the command line): added usage examples, sorted options by groups, added README references;
* Improved README, documented `as_lst` and `as_lst_exp` parsers.

### Version 2.7.2 (2022-08-12)

* Fix SEGFAULT in `deb1` and `deb2` parsers due to out of boundary labels lookup.

### Version 2.7.1 (2022-07-23)

* Fix incorrect newlines produced by `log` and `asm` output parsers on Windows;
* Fix a minor memory leak when a parser crashes;
* Overall stability and portability improvements.

### Version 2.7 (2021-04-27)

* Added support for multiple labels sharing the same offset for all input and output wrappers;

* `deb1` and `deb2` output parsers:
	- Add "/favorLastLabels" option, which toggles choosing last labels when there are multiple labels at the same offset (first labels are preferred otherwise).

### Version 2.6 (2021-02-01)

* Implemented offset masks support for all the input wrappers; leave only lower 24-bits of offsets by default;
* Added `-mask` option to configure offset masking;
* Added `-in` and `-out` options as shortcuts for `-input` and `-output` respectively;
* Added STDIN and STDOUT support when processing input and output respectively.

* `asm68k_sym` input parser:
	- Added local labels support (local labels are produced when assembled with v+ option);
	- Fixed missing offset boundary and transformation logic (applied by `-range`, `-base` and `-mask` options);
	- Added "/localSign", "/localJoin" and "/processLocals" options to configure local labels processing.
* `asm68k_lst` and `as_lst` input parsers:
	- Fixed a bug that prevented offsets >=$80000000 to be added due to incorrect signed boundary check;
	- When several labels occur on the same offset, use the last label met, not the first;
	- Track last global label name correctly (it previously didn't update the label when it was filtered via boundary or other checks).
* `deb1` output parser:
	- Fix memory corruption when symbol map requires more than 64 memory blocks;
	- Explicitly limit symbols map to 64 blocks, display an error when overflow was about to occur.
* `deb2` output parser:
	- Fix infinite loop when the full the last block id was 0xFFFF;
	- Limit symbols map to 256 blocks, display error if more blocks were requested.

### Version 2.5.2 (2020-08-09)

* Fix SEGFAULT when attempting to write inaccesible output file.
* Minor error handling improvements.

### Version 2.5.1 (2020-01-25)

* Fix displaying of certain error messages.

### Version 2.5 (2018-10-30)

* Optimized and imporved `asm68k_lst` parser.
* Improved handling of conflicting command-line options.
* Fixed memory leaks on program termination (in both successful and failure states).
* Overall stability and error handling improvements.

### Version 2.1 (2018-07-08)

* Added `-toupper` and `-tolower` options to convert all the processed symbols to uppercase or lowecase accordingly. This helps to reduce size of symbol data in DEB1/DEB2 formats, as the compression takes advantage of it.
* Added new `log` input parser to support plain-text **.log**/**.txt** files as input.

### Version 2.0 (2018-01-14)

Initial version 2.x release.
