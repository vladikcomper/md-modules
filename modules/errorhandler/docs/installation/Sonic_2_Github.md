
# Installing MD Debugger in Sonic 2 GitHub Disassembly

This guide describes a step-by-step installation process of the MD Error Handler and Debugger 2.5 and above in Sonic 2 GitHub Disassembly.

The base disassembly used for this installation is available here: https://github.com/sonicretro/s2disasm

## Step 1. Download and unpack the debugger

1. Open the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.5
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

1. Go back to the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.5

2. Download the ConvSym utility for your platform: Windows, Linux, FreeBSD or MacOS;

3. Extract the ConvSym executable to the correct path in your disassembly depending on your platform:

	- `build_tools\Windows-x86\convsym.exe` for Windows;
	- `build_tools/Linux-x86_64/convsym` for Linux (64-bit);
	- `build_tools/BSD-x86_64/convsym` for FreeBSD;
	- `build_tools/Mac-x86_64/convsym` for MacOS;

4. To properly append debug symbols, you need to disable automatic ROM padding first.

	Open `s2.asm` and search for `padToPowerOfTwo =`. You should see the following fragment:

	```m68k
	;	| If 0, a REV00 ROM is built
	;	| If 1, a REV01 ROM is built, which contains some fixes
	;	| If 2, a (probable) REV02 ROM is built, which contains even more fixes
	padToPowerOfTwo = 1
	```

	Change `padToPowerOfTwo = 1` to `padToPowerOfTwo = 0`.

5. Open `build.lua` and locate the following lines:

	```lua
	success_continue_wrapper(common.build_rom("s2", "s2built", "", "-p=0 -z=0," .. (improved_sound_driver_compression and "saxman-optimised" or "saxman-bugged") .. ",Size_of_Snd_driver_guess,after", true, repository))

	-- Correct some pointers and other data that we couldn't until after the ROM had been assembled.
	os.execute(tools.fixpointer .. " s2.h s2built.bin   off_3A294 MapRUnc_Sonic 0x2D 0 4   word_728C_user Obj5F_MapUnc_7240 2 2 1")
	```

6. Just **after** the lines above, insert the following:

	```lua
	-- Create DEBUG build
	success_continue_wrapper(common.build_rom("s2", "s2built.debug", "-D __DEBUG__ -OLIST s2.debug.lst", "-p=0 -z=0," .. (improved_sound_driver_compression and "saxman-optimised" or "saxman-bugged") .. ",Size_of_Snd_driver_guess,after", true, repository))
	os.execute(tools.fixpointer .. " s2.h s2built.debug.bin   off_3A294 MapRUnc_Sonic 0x2D 0 4   word_728C_user Obj5F_MapUnc_7240 2 2 1")
	```

7. Now, find `os.remove("s2.h")` line just below and right **after** it, insert this fragment:

	```lua
	-- Append debug symbols to ROMs using ConvSym
	local extra_tools = common.find_tools("debug symbol generator", "https://github.com/vladikcomper/md-modules", repository, "convsym")
	if extra_tools == nil then
		common.show_flashy_message("Build failed. See above for more details.")
		os.exit(false)
	end
	os.execute(extra_tools.convsym .. " s2.lst s2built.bin -input as_lst -range 0 FFFFFF -a")
	os.execute(extra_tools.convsym .. " s2.lst s2built.debug.bin -input as_lst -exclude -filter \"z[A-Z].+\" -range 0 FFFFFF -a")

	```

8. Finally, another few lines below you'll find `common.fix_header("s2built.bin")`. Right **after** it, also add this:

	```lua
	common.fix_header("s2built.debug.bin")
	```

<details>
<summary>Verifying that you've modified "build.lua" correctly</summary>

If you're having issues with insertions listed above or want to double-check, here's a full diff:

```diff
diff --git a/build.lua b/build.lua
index 2699ff3..0c9903b 100755
--- a/build.lua
+++ b/build.lua
@@ -157,11 +157,25 @@ success_continue_wrapper(common.build_rom("s2", "s2built", "", "-p=0 -z=0," .. (
 -- Correct some pointers and other data that we couldn't until after the ROM had been assembled.
 os.execute(tools.fixpointer .. " s2.h s2built.bin   off_3A294 MapRUnc_Sonic 0x2D 0 4   word_728C_user Obj5F_MapUnc_7240 2 2 1")
 
+-- Create DEBUG build
+success_continue_wrapper(common.build_rom("s2", "s2built.debug", "-D __DEBUG__ -OLIST s2.debug.lst", "-p=0 -z=0," .. (improved_sound_driver_compression and "saxman-optimised" or "saxman-bugged") .. ",Size_of_Snd_driver_guess,after", true, repository))
+os.execute(tools.fixpointer .. " s2.h s2built.debug.bin   off_3A294 MapRUnc_Sonic 0x2D 0 4   word_728C_user Obj5F_MapUnc_7240 2 2 1")
+
 -- Remove the header file, since we no longer need it.
 os.remove("s2.h")
 
+-- Append debug symbols to ROMs using ConvSym
+local extra_tools = common.find_tools("debug symbol generator", "https://github.com/vladikcomper/md-modules", repository, "convsym")
+if extra_tools == nil then
+	common.show_flashy_message("Build failed. See above for more details.")
+	os.exit(false)
+end
+os.execute(extra_tools.convsym .. " s2.lst s2built.bin -input as_lst -range 0 FFFFFF -a")
+os.execute(extra_tools.convsym .. " s2.lst s2built.debug.bin -input as_lst -exclude -filter \"z[A-Z].+\" -range 0 FFFFFF -a")
+
 -- Correct the ROM's header with a proper checksum and end-of-ROM value.
 common.fix_header("s2built.bin")
+common.fix_header("s2built.debug.bin")
 
 -- A successful build; we can quit now.
 os.exit(exit_code)
```
</details>

This will produce two builds for you: the RELEASE build (`s2built.bin`) and the DEBUG one (`s2built.debug.bin`). They should be identical for now, but if you start using some of the advanced debugger features, like assertions and `KDebug` interface, these features will be compiled and enabled only in DEBUG builds to avoid performance penalties when not debugging.

> **Note**
>
> AS compiles code in _case-insensitive mode_ by default. This means all symbols will be converted to upper-case. If you want to preserve case, add `-U` to compile flags to enable the _case-sensitive mode_. Beware that you may need to fix a lot of labels if their casing differs!

That's it! Save `build.lua` and run it (or `build.bat` on Windows as its launcher). Make sure the are no errors in the output.

## Step 5. Testing the debugger with an intentional crash

Now, let's try your freshly installed debugger in action. For testing purposes, let's make it so the game shows custom exception if you press A playing as Sonic. We then extend and customize our exception a little.

In `s2.asm`, find `Obj01_Normal:`. Right below it, add the following lines as shown:

```m68k
Obj01_Normal:
	btst	#button_A, Ctrl_1_Press_Logical	; is A pressed?
	beq.s	.skip				; if not, branch
	RaiseError "Intentional crash test"	;
.skip:
```

Now, build your ROM, start a level and press A at any time. You should see the generic exception screen (same as you get for a normal exception, except for the header). While on this screen, you can press B to display backtrace, A to which symbols are referenced by the address registers. Press Start or C button (if unmapped) to switch to the main exception screen.

Looks beautiful, isn't it? But there's more to it.

We can display additional information about our exception if needed:

```diff
-	RaiseError "Intentional crash test"
+	RaiseError "Intentional crash test:%<endl>Level ID: %<.w Current_ZoneAndAct>%<endl>Frame: %<.w Timer_frames>"
```

Now, let's test a sample debugger, shall we? Create a new `SampleDebugger.asm` file in your disassembly's root and paste the following code to it:

```m68k
SampleDebugger:
	Console.WriteLine "%<pal1>Camera (FG): %<pal0>%<.w Camera_X_pos>-%<.w Camera_Y_pos>"
	Console.WriteLine "%<pal1>Camera (BG): %<pal0>%<.w Camera_BG_X_pos>-%<.w Camera_BG_Y_pos>"
	Console.BreakLine
	
	Console.WriteLine "%<pal1>Objects IDs in slots:%<pal0>"
	Console.Write "%<setw>%<39>"       ; format slots table nicely ...

	lea 	Object_RAM, a0
	move.w 	#(LevelOnly_Object_RAM_End-Object_RAM)/object_size-1, d0
	
	.DisplayObjSlot:
	    Console.Write "%<.b (a0)> "
	    lea       next_object(a0), a0
	    dbf       d0, .DisplayObjSlot

	rts
```

Include your new file somewhere in `s2.asm`. I recommend including it right above the Error Handler (`include "ErrorHandler.asm"`):
```m68k
    include   "SampleDebugger.asm"
```

> **Warning**
>
> Remember not to include anything **after** `include "ErrorHandler.asm"` not to break debug symbol support.

To use this debugger in `RaiseError`, pass its label (`SampleDebugger`) as the second argument:
```diff
-	RaiseError "Intentional crash test:%<endl>Level ID: %<.w v_zone>%<endl>Frame: %<.w v_framecount>"
+	RaiseError "Intentional crash test:%<endl>Level ID: %<.w Current_ZoneAndAct>%<endl>Frame: %<.w Timer_frames>", SampleDebugger
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
