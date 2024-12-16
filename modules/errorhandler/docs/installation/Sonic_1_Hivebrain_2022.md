
# Installing MD Debugger in Sonic 1 Hivebrain 2022 Disassembly

This guide describes a step-by-step installation process of the MD Error Handler and Debugger 2.5 and above in Sonic 1 Hivebrain 2022 disassembly.

The base disassembly used for this installation is available here: https://github.com/cvghivebrain/s1disasm

> [!NOTE]
>
> You want a similar disassembly as a base, you can also try **Sonic 1-squared** disassembly, which already comes with MD Debugger and Error Handler pre-installed: https://github.com/cvghivebrain/Sonic1sq

## Step 1. Download and unpack the debugger

1. Open the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.6-mddebugger
2. Download `errorhandler-2.6.zip` from this page, find `axm68k` directory inside;
3. Extract files from the `axm68k` directory (AXM68K bundle) into disassembly's root directory.

## Step 2. Include debugger macros in your disassembly

Open `_Main.asm` file in your favorite text editor and add the following somewhere at the beginning (e.g. above `include "Macros.asm"`):

```m68k
	include	"Debugger.asm"
```

Don't try to build the ROM just yet. We're still missing one important component: the Error Handler itself!

## Step 3. Install the Error Handler

The `Debugger.asm` file you've included earlier is just a set of macros definitions. You cannot actually use them unless there's real code that handles exceptions, debug text rendering etc. So you must now include the Error Handler itself (the `ErrorHandler.asm` file that you've also copied).

> [!NOTE]
>
> Why cannot we just have both definitions and code in one file? It's because we need Error Handler's code at the very end of the ROM, but debugger macros should be available from the beginning. In C/C++ terms, one is a header, and the other is an actual object file that is linked (included) the last. While it's technically possible to include Error Handler anywhere after the ROM header (e.g. in the middle), it's absolutely required that the debug symbol table is included after it, which is only possible at the end of ROM.

1. At the very bottom of `_Main.asm`, just before `ROM_End:`, add the following snippet:

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

2. If you try to run `build.bat` now, you'll find quite a few errors related to multiply-defined labels. This is because the new error handler now conflicts with Sonic 1's native one. Fixing this is pretty straight-forward. Just remove the old code.

	In `_Main.asm`, find and remove the following line:

	```m68k
	    include	"Includes\Errors.asm"
	```

	This remoeves the original error handler. Let's also `Includes\Errors.asm` file as well, since we don't need it.

3. After removing the old exceptions code, run `build.bat` and make sure your ROM builds properly.

Once everything's done, congratulations, the Error Handler is installed, you're almost there!


## Step 4. Install ConvSym to generate debug symbols

> [!WARNING]
>
> This section is slightly incomplete, because it doesn't introduce DEBUG builds for features like KDebug and assertions.

1. Go back to the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.6-mddebugger

2. Download the ConvSym utility for Windows (or your current platform, e.g. Linux, FreeBSD, MacOS);

3. Extract `convsym.exe` to `bin/` directory in the disassembly.

4. Now, open `build.bat` and locate the following line:

	```shell
	"bin\axm68k.exe" /m /k /p _Main.asm, s1built.bin >errors.txt, , _Main.lst
	```

5. Replace all the lines above with the following code:

	```shell
	"bin\axm68k.exe" /m /k /p _Main.asm, s1built.bin >errors.txt, _Main.sym, _Main.lst
	"bin\convsym.exe" _Main.sym s1built.bin -a
	```

> [!NOTE]
>
> ASM68K compiles code in _case-insensitive mode_ by default. This means all symbols will be converted to lower-case. If you want to preserve case, add `/o c+` to compile flags to enable the _case-sensitive mode_. Beware that you may need to fix a lot of labels if their casing differs!

That's it! Save `build.bat` and run it. Make sure the are no errors in the output.
