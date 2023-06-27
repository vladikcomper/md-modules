
# Installing MD Debugger in Sonic 1 GitHub Disassembly (AS, Mid-2022)

> **Warning**
>
> This guide assumes your project is using a version of Sonic 1 GitHub disassembly dated between July 2022 and June 2023. It's when it switched to Lua-based build system introduced, but before it was refactored.
>
> For the newest version of the disassembly, see the other guide.

This guide describes a step-by-step installation process of the MD Error Handler and Debugger 2.5 and above in Sonic 1 GitHub Disassembly.

There are two main branches of this disassembly using the AS and ASM68K assemblers respectively. This guide targets the AS version of the disassembly. For the ASM68K version, see the other guide.

> **Note**
>
> The AS version of MD Debugger has slightly limited _formatted strings_ syntax. You probably won't notice this unless you're an advanced user (even so, there are workarounds), but bear in mind that MD Debugger was primarily developed for the ASM68K assembler and has better support for it.

The base disassembly used for this installation is available here: https://github.com/sonicretro/s1disasm

## Step 1. Download and unpack the debugger

1. Open the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.5
2. Download the AS version of MD Debugger (`errorhandler-as.7z`);
3. Extract its files into disassembly's root directory.

## Step 2. Include debugger macros in your disassembly

Open `sonic.asm` file in your favorite text editor and add the following like at the beginning to include Error Handler's main definitions:

```m68k
	include	"Debugger.asm"
```

Don't try to build the ROM just yet. We're still missing one important component: the Error Handler itself!

## Step 3. Install the Error Handler

The `Debugger.asm` file you've included earlier is just a set of macros definitions. You cannot actually use them unless there's real code that handles exceptions, debug text rendering etc. So you must now include the Error Handler itself (the `ErrorHandler.asm` file that you've also copied).

> **Note**
>
> Why cannot we just have both definitions and code in one file? It's because we need Error Handler's code at the very end of the ROM, but debugger macros should be available from the beginning. In C/C++ terms, one is a header, and the other is an actual object file that is linked (included) the last. While it's technically possible to include Error Handler anywhere after the ROM header (e.g. in the middle), it's absolutely required that the debug symbol table is included after it, which is only possible at the end of ROM.

1. At the very bottom of `sonic.asm`, just before `EndOfRom:`, add the following snippet:

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

2. If you try to run `build.lua` (or `build.bat` on Windows if Lua isn't globally available in your environment) now, you'll find quite a few errors related to multiply-defined labels. This is because the new error handler now conflicts with Sonic 1's native one. Fixing this is pretty straight-forward. Just remove the old code.

	In `sonic.asm`, find `BusError:`, which is the very first native exception handler.

	You need to remove all the code from the `BusError:` line through the end of "ErrorWaitForC:" (look for `; End of function ErrorWaitForC` line). This is approx. 175 lines of code to remove.

3. After removing the old exceptions code, run `build.lua`/`build.bat` and make sure your ROM builds properly.

Once everything's done, congratulations, the Error Handler is installed, you're almost there!

## Step 4. Install ConvSym to generate debug symbols


1. Go back to the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.5

2. Download the ConvSym utility for your platform: Windows, Linux, FreeBSD or MacOS;

3. Extract the ConvSym executable to the correct path in your disassembly depending on your platform:

	- `build_tools\Windows-x86\convsym.exe` for Windows;
	- `build_tools/Linux-x86_64/convsym` for Linux (64-bit);
	- `build_tools/BSD-x86_64/convsym` for FreeBSD;
	- `build_tools/Mac-x86_64/convsym` for MacOS;

4. Open `build.lua` and locate the following line:

	```lua
	-- Assemble the ROM.
	local assemble_result = common.assemble_file("sonic.asm", "s1built.bin", tools.as, "", tools.s1p2bin, improved_dac_driver_compression and "" or " -a", false)
	```

5. Just **after** the lines listed above, insert this new code:

	```lua
	if assemble_result == 'success' then
		assemble_result = common.assemble_file("sonic.asm", "s1built.debug.bin", tools.as, "-D __DEBUG__ -OLIST sonic.debug.lst", tools.s1p2bin, improved_dac_driver_compression and "" or " -a", false)
	end
	```

6. Now, locate these lines in the same file:

	```lua
	-- Correct the ROM's header with a proper checksum and end-of-ROM value.
	common.fix_header("s1built.bin")
	```

7. Just **before** the above lines, insert this:

	```lua
	-- Append symbol table to the ROM.
	local extra_tools, extra_platform_directory = common.find_tools("convsym")
	if not extra_tools then
		print(string.format("\z
			Couldn't find 'convsym' utility for your platform.n\z
			\n\z
			Make sure the appropriate executable is installed; if not, compile it from the source code avaliable here:\n\z
			'https://github.com/vladikcomper/md-modules/tree/master/utils/convsym'\n\z
			\n\z
			Once compiled, copy the executable to the '%s' directory of your project.", extra_platform_directory))
		os.exit(false)
	end
	os.execute(extra_tools.convsym .. " sonic.lst s1built.bin -input as_lst -exclude -filter \"z[A-Z].+\" -a")
	os.execute(extra_tools.convsym .. " sonic.debug.lst s1built.debug.bin -input as_lst -exclude -filter \"z[A-Z].+\" -a")
	```

8. Finally, **after** the `common.fix_header("s1built.bin")` line, add this:

	```lua
	common.fix_header("s1built.debug.bin")
	```

<details>
<summary>Verifying that you've modified "build.lua" correctly</summary>

If you're having issues with insertions listed above or want to double-check, here's a full diff:

```diff
diff --git a/build.lua b/build.lua
index 0426da0..1e352dc 100755
--- a/build.lua
+++ b/build.lua
@@ -42,6 +42,10 @@ os.rename("s1built.bin", "s1built.prev.bin")
 -- Assemble the ROM.
 local assemble_result = common.assemble_file("sonic.asm", "s1built.bin", tools.as, "", tools.s1p2bin, improved_dac_driver_compression and "" or " -a", false)

+if assemble_result == 'success' then
+       assemble_result = common.assemble_file("sonic.asm", "s1built.debug.bin", tools.as, "-D __DEBUG__ -OLIST sonic.debug.lst", tools.s1p2bin, improved_dac_driver_compression and "" or " -a", false)
+end
+
 if assemble_result == "crash" then
        print "\n\z
                **********************************************************************\n\z
@@ -66,8 +70,23 @@ elseif assemble_result == "error" then
        os.exit(false)
 end

+-- Append symbol table to the ROM.
+local extra_tools, extra_platform_directory = common.find_tools("convsym")
+if not extra_tools then
+       print(string.format("\z
+               Couldn't find 'convsym' utility for your platform.n\z
+               \n\z
+               Make sure the appropriate executable is installed; if not, compile it from the source code avaliable here:\n\z
+               'https://github.com/vladikcomper/md-modules/tree/master/utils/convsym'\n\z
+               \n\z
+               Once compiled, copy the executable to the '%s' directory of your project.", extra_platform_directory))
+       os.exit(false)
+end
+os.execute(extra_tools.convsym .. " sonic.lst s1built.bin -input as_lst -exclude -filter \"z[A-Z].+\" -a")
+os.execute(extra_tools.convsym .. " sonic.debug.lst s1built.debug.bin -input as_lst -exclude -filter \"z[A-Z].+\" -a")
+
 -- Correct the ROM's header with a proper checksum and end-of-ROM value.
 common.fix_header("s1built.bin")
+common.fix_header("s1built.debug.bin")
```
</details>

This will produce two builds for you: the RELEASE build (`s1built.bin`) and the DEBUG one (`s1built.debug.bin`). They should be identical for now, but if you start using some of the advanced debugger features, like assertions and `KDebug` interface, these features will be compiled and enabled only in DEBUG builds to avoid performance penalties when not debugging.

> **Note**
>
> AS compiles code in _case-insensitive mode_ by default. This means all symbols will be converted to upper-case. If you want to preserve case, add `-U` to compile flags to enable the _case-sensitive mode_. Beware that you may need to fix a lot of labels if their casing differs!

That's it! Save `build.lua` and run it (or `build.bat` on Windows as its launcher). Make sure the are no errors in the output.

## Step 5. Testing the debugger with an intentional crash

Now, let's try your freshly installed debugger in action. For testing purposes, let's make it so the game shows custom exception if you press A playing as Sonic. We then extend and customize our exception a little.

In `sonic.asm`, find `Sonic_Normal:`. Right below it, add the following lines as shown:

```m68k
Sonic_Normal:
	btst	#bitA, v_jpadpress2		; is A pressed?
	beq.s	.skip				; if not, branch
	RaiseError "Intentional crash test"	;
.skip:
```

Now, build your ROM, start a level and press A at any time. You should see the generic exception screen (same as you get for a normal exception, except for the header). While on this screen, you can press B to display backtrace, A to which symbols are referenced by the address registers. Press Start or C button (if unmapped) to switch to the main exception screen.

Looks beautiful, isn't it? But there's more to it.

We can display additional information about our exception if needed:

```diff
-	RaiseError "Intentional crash test"
+	RaiseError "Intentional crash test:%<endl>Level ID: %<.w v_zone>%<endl>Frame: %<.w v_framecount>"
```

Now, let's test a sample debugger, shall we? Create a new `SampleDebugger.asm` file in your disassembly's root and paste the following code to it:

```m68k
SampleDebugger:
	Console.WriteLine "%<pal1>Camera (FG): %<pal0>%<.w v_screenposx>-%<.w v_screenposy>"
	Console.WriteLine "%<pal1>Camera (BG): %<pal0>%<.w v_bgscreenposx>-%<.w v_bgscreenposy>"
	Console.BreakLine
	
	Console.WriteLine "%<pal1>Objects IDs in slots:%<pal0>"
	Console.Write "%<setw>%<39>"       ; format slots table nicely ...

	lea 	v_objspace, a0
	move.w 	#$2000/$40-1, d0
	
	.DisplayObjSlot:
	    Console.Write "%<.b (a0)> "
	    lea       $40(a0), a0
	    dbf       d0, .DisplayObjSlot

	rts
```

Include your new file somewhere in `sonic.asm`. I recommend including it right above the Error Handler (`include "ErrorHandler.asm"`):
```m68k
    include   "SampleDebugger.asm"
```

> **Warning**
>
> Remember not to include anything **after** `include "ErrorHandler.asm"` not to break debug symbol support.

To use this debugger in `RaiseError`, pass its label (`SampleLevelDebugger`) as the second argument:
```diff
-	RaiseError "Intentional crash test:%<endl>Level ID: %<.w v_zone>%<endl>Frame: %<.w v_framecount>"
+	RaiseError "Intentional crash test:%<endl>Level ID: %<.w v_zone>%<endl>Frame: %<.w v_framecount>", SampleLevelDebugger
```

If you now try to run it, you should see a differently looking exception screen. It now displays camera coordinates and object slots.

You can also use your debugger globally and call it from any exception. To demonstrate, let's map it to the C button of a generic exception screen. Open `Debugger.asm` and locate these lines:

```m68k
; Debuggers mapped to pressing A/B/C on the exception screen
; Use 0 to disable button, use debugger's entry point otherwise.
DEBUGGER__EXTENSIONS__BTN_A_DEBUGGER:	equ		Debugger_AddressRegisters	; display address register symbols
DEBUGGER__EXTENSIONS__BTN_B_DEBUGGER:	equ		Debugger_Backtrace			; display exception backtrace
DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER:	equ		0		; disabled
```

Try to change the value of `DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER` from `0` to `SampleDebugger`. Now pressing any the C button on any exception will call this debugger separately. Press Start to return to the main exception.

> **Note**
>
> You may notice that the screen contents are slightly different when `SampleDebugger` is called separately. This is because we don't have an exception header rendered and text itself is aligned differently when a debugger is invoked directly. If you want to align text the same way exception screen does it, you can add `Console.Write "%<setx>%<1>%<setw>%<38>"` at the beginning of the debugger.

When you've done playing, **feel free to revert any changes and intentionally thrown exceptions from this step.**
