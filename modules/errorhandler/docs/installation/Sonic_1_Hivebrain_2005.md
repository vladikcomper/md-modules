
# Installing MD Debugger in Sonic 1 Hivebrain 2005 Disassembly

> **Note**
>
> Sonic 1 Hivebrain 2005 Disassembly is outdated and its usage is generally not recommended for newer projects. If you're looking to start a fresh project, consider using modern disassemblies like Sonic 1 GitHub Disassembly instead.

This guide describes a step-by-step installation process of the MD Error Handler and Debugger 2.5 and above in Sonic 1 Hivebrain 2005 disassembly. It targets the ASM68K version of the disassembly, which was the most commonly used at the time.

The base disassembly used for this installation is available here: https://info.sonicretro.org/images/5/5f/Sonic_1_%28Split_and_Text_by_Hivebrain%29_%28ASM68K%29.zip

## Step 1. Download and unpack the debugger

1. Open the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.0
2. Download the ASM68K version of MD Debugger (`errorhandler-asm68k.7z`);
3. Extract its files into disassembly's root directory.

## Step 2. Include debugger macros in your disassembly

Open `sonic1.asm` file in your favorite text editor and add the following like at the beginning to include Error Handler's main definitions:

```68k
	include	"Debugger.asm"
```

Run `build.bat` to make sure your diassembly builds properly and there are no conflicting labels. For the vanilla disassembly, you'll most likely get the following error:

```
<...> Error : Label 'console' multiply defined
console: dc.b 'SEGA MEGA DRIVE '
```

This is because debugger definitions use Console as a namespace for new set of console-related commands (`Console.Write`, `Console.Run` etc), which conflicts with ROM header label with the same name.

To fix this, search for "Console:" in `sonic1.asm`. You should find the conflicting line. Just remove "Console:" part (it's not used anyways) like so:

```diff
+Console:	dc.b 'SEGA MEGA DRIVE ' ; Hardware system ID
-			dc.b 'SEGA MEGA DRIVE ' ; Hardware system ID
```

Your project should now build fine, so it's time to install Error Handler itself!

## Step 3. Install the Error Handler 

`Debugger.asm` file you've included earlier is just a set of macros definitions. You cannot actually use them unless there's real code that handles exceptions, debug text rendering etc. So you must now include Error Handler itself (the `ErrorHandler.asm` file that you've also copied).

> **Note**
>
> Why cannot we just have both definitions and code in one file? It's because we need Error Handler's code at the very end of the ROM, but debugger macros should be available from the beginning. In C/C++ terms, one is a header, and the other is an actual object file that is linked (included) the last. While it's technically possible to include Error Handler anywhere after the ROM header (e.g. in the middle), it's absolutely required that the debug symbol table is included after it, which is only possible at the end of ROM.

At the very bottom of `sonic1.asm`, just before "EndOfRom:", add the following snippet:

```68k
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

The "WARNING!" comment in the snipped is just so you don't forget that _you cannot put anything_ after `include "ErrorHandler.asm"`, otherwise debug symbols cannot be used, because they will be appended just after the end of the ROM by ConvSym utility.

If you try to run `build.bat` now, you'll find a lot more errors related to multiply-defined labels. This is because the new error handler now conflicts with Sonic 1's native one. Fixing this is pretty straight-forward. Just remove the old code:

In `sonic1.asm`, find `BusError:`, which is the very first native exception handler. You need to remove all the code from the `BusError:` line through the end of "ErrorWaitForC:" (look for `; End of function ErrorWaitForC` line). This is approx. 175 lines of code to remove.

After removing the old exceptions code, run `build.bat` and make sure your ROM builds properly. If it does, congratulations, the Error Handler is installed, you're almost there!

## Step 4. Fix disassembly problems: SEGA PCM sound

If you're using a vanilla disassembly with the native DAC driver, you may now hear a short audio glitch at the end of "SEGA" scream. This is a small disassembly problem in how it uses labels to determine the start and the end of SEGA PCM sample.

In `sonic1.asm`, search for `Kos_Z80:` and you'll see these lines:

```68k
Kos_Z80:	incbin	sound\z80_1.bin
			dc.w ((SegaPCM&$FF)<<8)+((SegaPCM&$FF00)>>8)
			dc.b $21
			dc.w (((EndOfRom-SegaPCM)&$FF)<<8)+(((EndOfRom-SegaPCM)&$FF00)>>8)
			incbin	sound\z80_2.bin
			even
```

As you see it references to `EndOfRom` label to determine the lengths of `SegaPCM`, but we've just included the Error Handler before it! So the glitch you hear is the DAC driver trying to play Error Handler's code as a sound, which happens to be follow the real PCM data.

To fix this, let's add a new label `SegaPCM_End` to mark an actual end of the sample.

In `sonic1.asm`, find `SegaPCM:` and insert `SegaPCM_End:` just after the `incbin`:

```diff
 SegaPCM:	incbin	sound\segapcm.bin
+SegaPCM_End:
 			even
```

Now, go back to `Kos_Z80:` and on the next few lines replace `EndOfRom` with `SegaPCM_End`:

```diff
 Kos_Z80:	incbin	sound\z80_1.bin
			dc.w ((SegaPCM&$FF)<<8)+((SegaPCM&$FF00)>>8)
			dc.b $21
-			dc.w (((EndOfRom-SegaPCM)&$FF)<<8)+(((EndOfRom-SegaPCM)&$FF00)>>8)
+			dc.w (((SegaPCM_End-SegaPCM)&$FF)<<8)+(((SegaPCM_End-SegaPCM)&$FF00)>>8)
			incbin	sound\z80_2.bin
			even
```

Now run `built.bat` again make sure SEGA sounds clean again.

> **Note**
>
> If your disassembly has diverged from the original quite a lot, you may still have glitches in SEGA PCM. This is likely because the sample crosses 32 KB ROM boundary, which the native DAC driver cannot handle. The easiest (but often not the most space-efficient) way to fix this is to add `align $8000` before `SegaPCM:` to align it again.


## Step 5. Install ConvSym for debug symbol generation

1. Go back to the release page for the recent version of MD Debugger on GitHub: https://github.com/vladikcomper/md-modules/releases/tag/v.2.0
2. Download the ConvSym utility for Windows (or your current platform, e.g. Linux, FreeBSD, MacOS);
3. Extract `convsym.exe` to your disassembly's root directory.

Now, open `build.bat` and locate the following lines:

```sh
asm68k /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- sonic1.asm, s1built.bin
rompad.exe s1built.bin 255 0
fixheadr.exe s1built.bin
```

Replace all the lines above with the following code:

```sh
rem RELEASE BUILD
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /p sonic1.asm, s1built.bin, s1built.sym, s1built.lst
convsym.exe s1built.sym s1built.bin -a
rompad.exe s1built.bin 255 0
fixheadr.exe s1built.bin

rem DEBUG BUILD
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /p /e _DEBUG_=1 sonic1.asm, s1built.debug.bin, s1built.debug.sym, s1built.debug.lst
convsym.exe s1built.debug.sym s1built.debug.bin -a
rompad.exe s1built.debug.bin 255 0
fixheadr.exe s1built.debug.bin
```

That's it! Save `build.bat` and run it. Make sure the are no errors in the output.

## Step 6. Testing the debugger with an intentional crash

Now, let's try your freshly installed debugger in action. For testing purposes, let's make it so the game shows custom exception if you press A playing as Sonic. We then extend and customize our exception a little.

In `sonic1.asm`, find `Obj01_Normal:`. Right below it, add the following lines as shown:

```diff
 Obj01_Normal:
+	btst	#6, ($FFFFF603).w 	; is A pressed?
+	beq.s	@skip				; if not, branch
+	RaiseError "Intentional crash test"
+@skip:
```

Now, build your ROM, start a level and press A at any time. You should see the generic exception screen (same as you get for a normal exception, except for the header). While on this screen, you can press B to display backtrace, A to which symbols are referenced by the address registers. Press Start or C button (if unmapped) to switch to the main exception screen.

Looks beautiful, isn't it? But there's more to it.

We can display additional information about our exception if needed:

```diff
-	RaiseError "Intentional crash test"
+	RaiseError "Intentional crash test:%<endl>Level ID: %<.w $FFFFFE10>%<endl>Frame: %<.w $FFFFFE04>"
```

Now, let's test a sample debugger, shall we? Create a new `SampleDebugger.asm` file in your disassembly's root and paste the following code to it:
```68k
SampleDebugger:
	Console.WriteLine "%<pal1>Camera (FG): %<pal0>%<.w $FFFFF700>-%<.w $FFFFF704>"
	Console.WriteLine "%<pal1>Camera (BG): %<pal0>%<.w $FFFFF708>-%<.w $FFFFF70C>"
	Console.BreakLine
	
	Console.WriteLine "%<pal1>Objects IDs in slots:%<pal0>"
	Console.Write "%<setw,39>"       ; format slots table nicely ...

	lea 	($FFFFD000).w, a0
	move.w 	#$2000/$40-1, d0
	
	@DisplayObjSlot:
	    Console.Write "%<.b (a0)> "
	    lea       $40(a0), a0
	    dbf       d0, @DisplayObjSlot

	rts
```

Include your new file somewhere in `sonic1.asm`. I recommend including it right above the Error Handler (`include "ErrorHandler.asm"`):
```68k
    include   "SampleDebugger.asm"
```

> **Warning**
>
> Remember not to include anything **after** `include "ErrorHandler.asm"` not to break debug symbol support.

To use this debugger in `RaiseError`, pass its label (`SampleLevelDebugger`) as the second argument:
```diff
-	RaiseError "Intentional crash test:%<endl>Level ID: %<.w $FFFFFE10>%<endl>Frame: %<.w $FFFFFE04>"
+	RaiseError "Intentional crash test:%<endl>Level ID: %<.w $FFFFFE10>%<endl>Frame: %<.w $FFFFFE04>", SampleLevelDebugger
```

If you now try to run it, you should see a differently looking exception screen. It now displays camera coordinates and object slots.


