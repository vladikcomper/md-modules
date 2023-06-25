
# Installing MD Debugger in Sonic 2 GitHub Disassembly

This guide describes a step-by-step installation process of the MD Error Handler and Debugger 2.5 and above in Sonic 2 GitHub Disassembly.

The base disassembly used for this installation is available here: https://github.com/sonicretro/s2disasm

## Step 1. Download and unpack the debugger

1. Open the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.0
2. Download the AS version of MD Debugger (`errorhandler-as.7z`);
3. Extract its files into disassembly's root directory.

## Step 2. Include debugger macros in your disassembly

Open `s2.asm` in your favorite text editor and paste the following right **above** `StartOfRom:`:

	```m68k
		include	"Debugger.asm"
	```

Don't try to build the ROM just yet. We're still missing one important component: the Error Handler itself!

## Step 3. Install the Error Handler 

The `Debugger.asm` file you've included earlier is just a set of macros definitions. You cannot actually use them unless there's real code that handles exceptions, debug text rendering etc. So you must now include the Error Handler itself (the `ErrorHandler.asm` file that you've also copied).

> **Note**
>
> Why cannot we just have both definitions and code in one file? It's because we need Error Handler's code at the very end of the ROM, but debugger macros should be available from the beginning. In C/C++ terms, one is a header, and the other is an actual object file that is linked (included) the last. While it's technically possible to include Error Handler anywhere after the ROM header (e.g. in the middle), it's absolutely required that the debug symbol table is included after it, which is only possible at the end of ROM.

1. At the very bottom of `s2.asm`, find `; end of 'ROM'`, and just **above** it, add the following snippet:

	```m68k
	; ==============================================================
	; --------------------------------------------------------------
	; Debugging modules
	; --------------------------------------------------------------

	   include   "ErrorHandler.asm"

	; --------------------------------------------------------------
	; WARNING!
	;	DO NOT put any data from now on! DO NOT use ROM padding!
	;	Symbol data should be appended here after ROM is compiled
	;	by ConvSym utility, otherwise debugger modules won't be able
	;	to resolve symbol names.
	; --------------------------------------------------------------
	```

	This includes entry points for exception vectors (Illegal instruction, Address Error etc), error handler configuration and the blob itself along with extensions (all inlined in the assembly file).

	The "WARNING!" comment in the snippet is just so you don't forget that _you cannot put anything_ after `include "ErrorHandler.asm"`, otherwise debug symbols cannot be used, because they will be appended just after the end of the ROM by ConvSym utility.

2. Now we need to actually attach point exceptions in the ROM's vector table to the error handler. To do so, in `s2.asm` find `Vectors:` and replace everything from the line `Vectors:` through `; byte_100:` with the following snippet:

	```m68k
	Vectors:
		dc.l System_Stack	; Initial stack pointer value
		dc.l EntryPoint		; Start of program
		dc.l BusError		; Bus error
		dc.l AddressError	; Address error (4)
		dc.l IllegalInstr	; Illegal instruction
		dc.l ZeroDivide		; Division by zero
		dc.l ChkInstr		; CHK exception
		dc.l TrapvInstr		; TRAPV exception (8)
		dc.l PrivilegeViol	; Privilege violation
		dc.l Trace			; TRACE exception
		dc.l Line1010Emu	; Line-A emulator
		dc.l Line1111Emu	; Line-F emulator (12)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (16)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (20)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (24)
		dc.l ErrorExcept	; Spurious exception
		dc.l ErrorExcept	; IRQ level 1
		dc.l ErrorExcept	; IRQ level 2
		dc.l ErrorExcept	; IRQ level 3 (28)
		dc.l H_Int			; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorExcept	; IRQ level 5
		dc.l V_Int			; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorExcept	; IRQ level 7 (32)
		dc.l ErrorExcept	; TRAP #00 exception
		dc.l ErrorExcept	; TRAP #01 exception
		dc.l ErrorExcept	; TRAP #02 exception
		dc.l ErrorExcept	; TRAP #03 exception (36)
		dc.l ErrorExcept	; TRAP #04 exception
		dc.l ErrorExcept	; TRAP #05 exception
		dc.l ErrorExcept	; TRAP #06 exception
		dc.l ErrorExcept	; TRAP #07 exception (40)
		dc.l ErrorExcept	; TRAP #08 exception
		dc.l ErrorExcept	; TRAP #09 exception
		dc.l ErrorExcept	; TRAP #10 exception
		dc.l ErrorExcept	; TRAP #11 exception (44)
		dc.l ErrorExcept	; TRAP #12 exception
		dc.l ErrorExcept	; TRAP #13 exception
		dc.l ErrorExcept	; TRAP #14 exception
		dc.l ErrorExcept	; TRAP #15 exception (48)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (52)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (56)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (60)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved)
		dc.l ErrorExcept	; Unused (reserved) (64)
	; byte_100:
	```

3. Now run `build.lua` (or `build.bat` on Windows if Lua isn't globally available in your environment) and make sure your ROM builds properly.

Once everything's done, congratulations, the Error Handler is installed, you're almost there!

## Step 4. Install ConvSym to generate debug symbols

1. Go back to the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.0

2. Download the ConvSym utility for your platform: Windows, Linux, FreeBSD or MacOS;

3. Extract the ConvSym executable to the correct path in your disassembly depending on your platform:

	- `build_tools\Windows-x86\convsym.exe` for Windows;
	- `build_tools/Linux-x86_64/convsym` for Linux (64-bit);
	- `build_tools/BSD-x86_64/convsym` for FreeBSD;
	- `build_tools/Mac-x86_64/convsym` for MacOS;

4. Open `build.lua` and locate the following line:

_To be continued_
