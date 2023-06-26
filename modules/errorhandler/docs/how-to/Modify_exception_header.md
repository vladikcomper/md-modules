
# How-to add your details in exception headers

This quick guide shows how to append your own messages to the standard exception headers. This is useful for leaving user instructions and contact information for reporting bugs.

## Compatibility

This guide applies to any project, disassembly and any version of MD Debugger (both AS and ASM68K).

## Instructions

### Step 1. Setting up a header extension

1. Open `ErrorHandler.asm` file and locate the following lines:

	```m68k
	BusError:
		__ErrorMessage "BUS ERROR", _eh_default|_eh_address_error

	AddressError:
		__ErrorMessage "ADDRESS ERROR", _eh_default|_eh_address_error

	IllegalInstr:
		__ErrorMessage "ILLEGAL INSTRUCTION", _eh_default

	ZeroDivide:
		__ErrorMessage "ZERO DIVIDE", _eh_default

	ChkInstr:
		__ErrorMessage "CHK INSTRUCTION", _eh_default

	TrapvInstr:
		__ErrorMessage "TRAPV INSTRUCTION", _eh_default

	PrivilegeViol:
		__ErrorMessage "PRIVILEGE VIOLATION", _eh_default

	Trace:
		__ErrorMessage "TRACE", _eh_default

	Line1010Emu:
		__ErrorMessage "LINE 1010 EMULATOR", _eh_default

	Line1111Emu:
		__ErrorMessage "LINE 1111 EMULATOR", _eh_default

	ErrorExcept:
		__ErrorMessage "ERROR EXCEPTION", _eh_default
	```

2. We're going to create a custom C-string that will be appended to every exception invocation listed above. To do that insert the following somewhere **before** the frament above:

	```m68k
	Str_ErrorHeader:
		dc.b	"Dummy common header", endl, endl
		dc.b	0
	```

3. Now, let's make use of `Str_ErrorHeader`. Append all exception messages from step 1 with `%<.l #Str_ErrorHeader str>`. You should end up with the following code:

	```m68k
	BusError:
		__ErrorMessage "%<.l #Str_ErrorHeader str>BUS ERROR", _eh_default|_eh_address_error

	AddressError:
		__ErrorMessage "%<.l #Str_ErrorHeader str>ADDRESS ERROR", _eh_default|_eh_address_error

	IllegalInstr:
		__ErrorMessage "%<.l #Str_ErrorHeader str>ILLEGAL INSTRUCTION", _eh_default

	ZeroDivide:
		__ErrorMessage "%<.l #Str_ErrorHeader str>ZERO DIVIDE", _eh_default

	ChkInstr:
		__ErrorMessage "%<.l #Str_ErrorHeader str>CHK INSTRUCTION", _eh_default

	TrapvInstr:
		__ErrorMessage "%<.l #Str_ErrorHeader str>TRAPV INSTRUCTION", _eh_default

	PrivilegeViol:
		__ErrorMessage "%<.l #Str_ErrorHeader str>PRIVILEGE VIOLATION", _eh_default

	Trace:
		__ErrorMessage "%<.l #Str_ErrorHeader str>TRACE", _eh_default

	Line1010Emu:
		__ErrorMessage "%<.l #Str_ErrorHeader str>LINE 1010 EMULATOR", _eh_default

	Line1111Emu:
		__ErrorMessage "%<.l #Str_ErrorHeader str>LINE 1111 EMULATOR", _eh_default

	ErrorExcept:
		__ErrorMessage "%<.l #Str_ErrorHeader str>ERROR EXCEPTION", _eh_default
	```

4. Now build your ROM to make sure everything is set correctly. The easiest way to test the change is to use `illegal` instruction anywhere in your code. Once it executes, you should see the extended header in your screen.

### Step 2. Customize your text

Now it's time to make this placeholder message fancier!

You can use the following special bytes to format it:

- `endl` - Starts a new line
- `pal0` - Use palette line #0 (white)
- `pal1` - Use palette line #1 (yellow)
- `pal2` - Use palette line #2 (blue)
- `pal3` - Use palette line #3 (dark-blue)

Here's an example of various flags in action:

```m68k
Str_ErrorHeader:
	dc.b	pal0,"This hack is experiencing technical", endl
	dc.b	"difficulties, please stand by~", endl, endl
	dc.b	pal3,"Please send the following information", endl
	dc.b	"to ",pal2,"megahacker777@mail.kool",pal3,":",pal0,endl,endl
	dc.b	0
	even
```

Notice how this also modifies the color of actual exception message.

Try out various options and choose whatever fulfils you needs!
