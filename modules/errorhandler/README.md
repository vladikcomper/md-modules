
# MD Debugger and Error Handler

![Illegal instruction](docs/.images/eh_illegal_instr.png) ![Backtrace](docs/.images/eh_custom_debugger.png)

___MD Debugger and Error Handler___ (or simply "MD Debugger", also known as _"The Advanced Error Handler and Debugger"_) is a ready-to-use error handler that comes with a powerful integrated debugger. It aims to provide robust and extensible debugging tools built-in directly into the Mega-Drive ROM, that can be used anywhere (from emulators to the real hardware).

Currently, it targets **The AS Macroassembler** and **ASM68K** assemblers. It has installation instructions and full support for the mainline Sonic disassemblies, but it can be integrated into any AS or ASM68K project (both the error handler and debugger) or even any pre-existing ROM (error handler only in a binary form).

## Features

![KDebug](docs/.images/eh_kdebug.png)

- __Debug symbol support.__
  - It can extract source code symbols at build time and bundle them with the ROM;
  - Debug symbols are efficiently compressed to save space and stored in custom database-like format; they are **not** visible as plain-text.
  - Error dumps will display symbols from your source code instead of raw offsets, making debugging crashes much easier;

- __Backtrace support, caller guessing and more.__
  - Press the B button on the exception screen to display the backtrace and see the full call chain that led to the exception;
  - Press the A button to display which symbols address registers point to;
  - Generic exception screen displays a caller out-of-the box.

- __Detailed and informative exceptions.__
  - Generic exception screen is as detailed and informative as possible;
  - See exception location, caller address, all the main CPU registers, stack dump and more;
  - Additional details can be displayed like VInt and HInt addresses (if dynamic) as well as `USP` and `SR` registers.

- __Easily write your own debuggers with "high-level" macros.__
  - Write your own debug programs to display what you need;
  - Use "high-level" macros that debugger environment provides, like `Console.Write "My d0 is %<.w d0 hex>"`;
  - Formatted string syntax in the debugger is extremely powerful: display any value from any memory location as: hexadecimal, decimal, binary, signed, unsigned, symbol or even a null-terminated ASCII string. Control output by modifying colors or adding line breaks.

- __Throw custom exceptions and customize error handling.__
  - You can throw custom exceptions at any time using `RaiseError` macro;
  - Use your own debug programs in exceptions if needed;
  - Customize generic exception screen showing or hiding some less frequently used exception details;
  - Map your debug programs to buttons on the exception screen.

- __Assertions.__
  - Use one of the most powerful debugging techniques and take advantage of self-testing code!
  - Assertions, widely adopted by many high-level languages, are provided by the debugger out-of-the box;
  - Use `assert` pseudo-instruction that is only compiled in DEBUG builds. This means zero run-time cost for your final (RELEASE) builds to implement self-testing code.

- __KDebug integration for logging, breakpoints and cycle-counting.__
  - Display formatted strings at any point straight in your emulator's debug console!
  - Use a similar "high-level" macro interface as in console programs (`KDebug.WriteLine` instead of `Console.WriteLine`), but without interrupting your programs;
  - Currently, the only emulators to support KDebug are Gens KMod and Blastem-nightly;
  - Create manual breakpoints with `KDebug.BreakPoint`;
  - Measure your code performance using `KDebug.StartTimer` and `KDebug.EndTimer`.

- __Easy to install and extremely lightweight.__
  - Error handler blob is below 4 KiB, which is quite small for the number of features it provides; optional debugger extensions take a few hundreds of bytes each;
  - It's quite easy to install, with installation instructions and ready configurations provided for the most mainline Sonic disassemblies.


## Projects with MD Debugger

The following ready-to-use open-source projects come with MD Debugger and Error Handler pre-installed:

- **SGDK** (Error Handler only) - https://github.com/Stephane-D/SGDK
- **Sonic Clean Engine (S.C.E.)** - https://github.com/TheBlad768/Sonic-Clean-Engine-S.C.E.-
- **Sonic 1 in Sonic 3 & Knuckles (S.C.E. Version)** - https://github.com/TheBlad768/Sonic-1-in-Sonic-3-S.C.E.-
- **Sonic 1-squared** - https://github.com/cvghivebrain/Sonic1sq


## Installation instructions

Installation instructions are provided for:

- [Sonic 1 GitHub Disassembly (AS version)](docs/installation/Sonic_1_Github_AS.md)
- [Sonic 1 GitHub Disassembly (ASM68K version)](docs/installation/Sonic_1_Github_ASM68K.md)
- [Sonic 1 Hivebrain 2005 Disassembly](docs/installation/Sonic_1_Hivebrain_2005.md)
- [Sonic 1 Hivebrain 2022 Disassembly](docs/installation/Sonic_1_Hivebrain_2022.md)
- [Sonic 2 GitHub Disassembly](docs/installation/Sonic_2_Github.md)

If you'd like to contribute new installation instructions or update the existing ones, feel free to open a Pull Request: https://github.com/vladikcomper/md-modules/pulls

## Documentation and help

### Guides

- [Powerful debugging techniques](docs/how-to/Debugging_techniques.md)
- [How-to add your details in exception headers](docs/how-to/Modify_exception_header.md)
- [Using KDebug integration](docs/how-to/Use_KDebug_integration.md)
- [Troubleshooting](docs/how-to/Troubleshoot.md)

### References

- [Debugger macro reference](docs/Debug_macros.md)
- [Formatted string format reference](docs/Formatted_strings.md)

## Supported assemblers

Currently, the *MD Debugger and Error Handler* supports integration with the following assemblers:

* __ASM68K__ (`asm68k` bundle, recommended)
  * __AXM68K__, a hacked ASM68K usually bundled with macros for Z80 assembly support (`axm68k` bundle);
* __The AS Macroassembler__ v.1.42 Bld 212 and above (`as` bundle, slightly limited support for some macro features)
* __GNU Assembler (GAS)__ (`gas` bundle, error handler only, no debugger macro support)


## Version History

### Version 2.6 (2024-12-15)

![Compact offsets](docs/.images/eh_address_error_v.2.6.png) ![Better assertions](docs/.images/eh_assertion_v.2.6.png)

- Official AXM68K and GAS support (allows SGDK integration), support for ASM68K projects using Psy-Q Linker; the following new bundles were added:
  - `axm68k` (for AXM68K)
  - `axm68k-extsym` (AXM68K, dynamic symbol table location)
  - `asm68k-linkable` (for ASM68K + Psylink)
  - `gas` (GNU Assembler)
- Error handler now uses compact offsets and symbol displacements: offsets are rendered as 24-bit instead of 32-bit (because M68K has a 24-bit bus anyways), and displacements don't have leading zeros (`+000X` is now `+X`):
  - This makes offsets more readable and allows to fit more characters on a line;
  - You can still revert to 32-bit offsets by changing `DEBUGGER__STR_OFFSET_SELECTOR` option in debugger config;
- Improved assertions (`assert` macro):
  - You can now assign a debugger to use when assertion fails, e.g. `assert.w d0, eq, #$1234, MyDebuggerIfItFails`;
  - Save/restore CCR in `assert` macro, so conditional flags aren't affected by it (this was already done in other macros);
  - Assertion failed exception now displays the original source code line and the received value;
- Error handler now also recognizes dynamic VInt/HInt jump handlers if they use `jmp (xxx).w` opcode instead of `jmp (xxx).l`;
- `KDebug` integration is finalized and is no longer experimental:
  - You can now use `KDebug.Write[Line]` macros in Console programs (they previously were suppressed due to VDP access conflicts);
  - `KDebug.Write[Line]` now properly skips unsupported multi-byte flags in formatted strings (e.g. `%<setw,40>`);
- Performance of `Console.WriteLine`, `Console.Write`, `KDebug.WriteLine`, `KDebug.Write` is now much faster when formatted string doesn't include any printable arguments;
- Introduce `_Console.*`, `_KDebug.*`, `_assert` macros ("shadow macros"): they behave like the original ones, but don't save/restore CCR; advanced users may take advantage of them for minor optimizations;
- `Console.WriteLine` and `Console.Write` now always restore last VRAM write location and won't break if your code writes to other VRAM locations in-between them;
- **AS version:** Support `xxx.w`, `(xxx).w`, `xxx.l` and `(xxx).l` syntax in formatted string arguments;
- **AS version:** Support missing `vc`, `vs` (overflow set/clear) conditions in `assert` macro (it was already supported in ASM68K version);
- **ASM68K version:** Fully support projects using "." instead of "@" for local labels (previously debugging macros could break local label scopes);
- **ASM68K version:** Support projects compiled with `/o ae+` option (it could previously cause issues when storing formatted strings);
- **ASM68K version:** Don't allow `X(sp)`, `-(sp)`, `(sp)+` in formatted strings (e.g. `"%<.w 4(sp) sym>"`); it was already unsupported in AS version, because this can lead to unexpected results or crashes;
- **ASM68K version:** Better error reporting in formatted strings: properly report missing a closing bracket for `%<`;
- **ASM68K version:** Warn if project does not set `/o ws+` flag as it breaks most of the debugger macros;
- **ASM68K version:** Replace `endc` directives with `endif` for readability;
- **ASM68K-Linkable version:** place strings of debugger macros (`.Write`, `.WriteLine`, `RaiseError` etc) in a separate section instead of inlining them, making generated code much smaller;
- Replace `__global__*` prefix for exported labels with `MDDBG__*`;
- Make console detection in `Console.*` macros much safer; they previously read a magic byte `Console.Magic(usp)` to tell if `usp` pointed to valid Console data, but it could crash when reading from invalid memory; magic byte is now stored in MSB of `usp` to mark pointer itself valid;
- Upgraded ConvSym from version 2.9.1 to 2.12.1, which adds the following major improvements:
  - Fixed a rare symbol encoding issue where data with unusual entropy would produce long prefix trees with some codes exceeding 16-bits, corrupting a small set of symbol texts;
  - Fixed another rare symbol encoding bug where if symbol heap for a memory block exceeds 64 KB and stops accepting symbols, all symbols in further blocks are also discarded;
  - Added new `txt` input parser for parsing generic text files using a configurable format string (this allows to parse SGDK's `symbol.txt` file);
  - Added support for symbol references instead of raw offsets in `-ref` and `-org` options (e.g. `-ref @MySymbol`);
  - Added `-addprefix` option to prefix all output symbols with a given string;
- **Bugfix:** Fix `%<palN>` flags clearing priority and XY-flip bits of Console's base pattern on top of changing palette bits;
- **Bugfix:** Fix a bug introduced in v.2.5 where "VInt:", "HInt:" couldn't properly render `<undefined>` text if VInt or HInt handlers were dynamic (in RAM), but their target locations weren't understood.
- **Bugfix:** Fix a rare buffer over-read in `Console.Write[Line]` and `KDebug.Write[Line]` and other macros using formatting strings if buffer flush occurs exactly in the middle of multi-byte formatting flag (e.g. `setw,40`);
- General optimizations and stability improvements.

### Version 2.5 (2023-06-30)

![Backtrace](docs/.images/eh_backtrace.png) ![Address registers](docs/.images/eh_address_regs.png)

- Introduced debugger extensions and the following new built-in debuggers:
  - Backtrace debugger (mapped to the B button by default);
  - Address register debugger (mapped to the A button by default).
- Upgraded ConvSym from version 2.0 to 2.9.1. This adds the following major features for debug symbol generation:
  - Stable AS support;
  - Improve symbol data compression by force-converting your symbols to upper or lowecase;
  - Support for multiple labels on the same offset;
  - Support for symbols in RAM section (must be properly implemented in your project);
  - Advanced offset transformations: mask, upper/bottom boundary, add/subtract base address;
- Added `assert` macro.
- Implemented `KDebug` integration with the following new macros:
  - `KDebug.WriteLine`
  - `KDebug.Write`
  - `KDebug.BreakLine`
  - `KDebug.BreakPoint`
  - `KDebug.StartTimer`
  - `KDebug.EndTimer`
- Added additional `Console.*` macros:
  - `Console.Clear`
  - `Console.Pause`
  - `Console.Sleep`
- Improve readability of offsets and symbols in the exception header;
- Renamed "Module:" field in exception header to "Offset:" for clarity;
- **ASM68K version:** Support "case-sensitive" compile-flag;
- **AS version:** Most of the M68K addressing modes are now supported in formatted strings. The following examples now work:
  - `%<.w #1234>`
  - `%<.w #SomeSymbolAsValue>`
  - `%<.l $FF0000>`
  - `%<.b 1(a0)>`
  - `%<.b something(a0)>`
  - `%<.b SomeLabel(pc)>`
- **AS version:** Add a workaround for an assembler bug in older builds of AS which may cause some instructions to be misaligned;
- **AS version:** Macro invocations (`Console.*`, `RaiseError`) no longer break local labels if placed in-between them;
- **AS version:** Prefer `!align` instead of `align` to avoid issues if it's overridden in the project;
- **AS version:** Support "case-sensitive" compile flag;
- Support full address range for stack pointer (previous version only correctly worked with $FF8000-$FFFFFF range due to optimizations);
- Introduce "External symbol table" bundles for both AS and ASM68K versions (`asm68k-extsym` and `as-extsym`), which uses a reference to the symbol table instead of expecting it right after the Error Handler blob;
- **Bugfix:** Fixed a rare case of buffer overflow when displaying offset as a symbol with displacement;
- Code-size optimizations, minor bugfixes and stability improvements.

### Version 2.0 (2018-01-14)

The original version 2.x release
