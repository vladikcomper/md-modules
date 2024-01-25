; ---------------------------------------------------------------
; Creates assertions for debugging
; ---------------------------------------------------------------
; EXAMPLES:
;	assert.b	d0, eq, #1		; d0 must be $01, or else crash!
;	assert.w	d5, eq			; d5 must be $0000!
;	assert.l	a1, hi, a0		; asert a1 > a0, or else crash!
;	assert.b	MemFlag, ne		; MemFlag must be non-zero!
; ---------------------------------------------------------------

assert	macro	src, cond, dest
#ifndef MD-SHELL
	; Assertions only work in DEBUG builds
	if def(__DEBUG__)
#endif
	if narg=3
		cmp.\0	\dest, \src
	else narg=2
		tst.\0	\src
	endif
		b\cond\.s	@skip\@
		RaiseError	"Assertion failed:%<endl>\src \cond \dest"
	@skip\@:
#ifndef MD-SHELL
	endif
#endif
	endm

; ---------------------------------------------------------------
; Raises an error with the given message
; ---------------------------------------------------------------
; EXAMPLES:
;	RaiseError	"Something is wrong"
;	RaiseError	"Your D0 value is BAD: %<.w d0>"
;	RaiseError	"Module crashed! Extra info:", YourMod_Debugger
; ---------------------------------------------------------------

RaiseError &
	macro	string, console_program, opts

	pea		*(pc)
	move.w	sr, -(sp)
	__FSTRING_GenerateArgumentsCode \string
	jsr		MDDBG__ErrorHandler
	__FSTRING_GenerateDecodedString \string
	if strlen("\console_program")			; if console program offset is specified ...
		dc.b	\opts+_eh_enter_console|(((*&1)^1)*_eh_align_offset)	; add flag "_eh_align_offset" if the next byte is at odd offset ...
		even															; ... to tell Error handler to skip this byte, so it'll jump to ...
		if DEBUGGER__EXTENSIONS__ENABLE
			jsr		\console_program										; ... an aligned "jsr" instruction that calls console program itself
			jmp		MDDBG__ErrorHandler_PagesController
		else
			jmp		\console_program										; ... an aligned "jmp" instruction that calls console program itself
		endif
	else
		if DEBUGGER__EXTENSIONS__ENABLE
			dc.b	\opts+_eh_return|(((*&1)^1)*_eh_align_offset)			; add flag "_eh_align_offset" if the next byte is at odd offset ...
			even															; ... to tell Error handler to skip this byte, so it'll jump to ...
			jmp		MDDBG__ErrorHandler_PagesController
		else
			dc.b	\opts+0						; otherwise, just specify \opts for error handler, +0 will generate dc.b 0 ...
			even								; ... in case \opts argument is empty or skipped
		endif
	endif
	even

	endm

; ---------------------------------------------------------------
; Console interface
; ---------------------------------------------------------------
; EXAMPLES:
#ifndef MD-SHELL
;	Console.Run	YourConsoleProgram
#endif
;	Console.Write "Hello "
;	Console.WriteLine "...world!"
;	Console.SetXY #1, #4
;	Console.WriteLine "Your data is %<.b d0>"
;	Console.WriteLine "%<pal0>Your code pointer: %<.l a0 sym>"
; ---------------------------------------------------------------

Console &
	macro

	if strcmp("\0","write")|strcmp("\0","writeline")|strcmp("\0","Write")|strcmp("\0","WriteLine")
		move.w	sr, -(sp)

		__FSTRING_GenerateArgumentsCode \1

		; If we have any arguments in string, use formatted string function ...
		if (__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		@str\@(pc), a1
			jsr		MDDBG__Console_\0\_Formatted
			movem.l	(sp)+, a0-a2/d7
			if (__sp>8)
				lea		__sp(sp), sp
			else
				addq.w	#__sp, sp
			endif

		; ... Otherwise, use direct write as an optimization
		else
			move.l	a0, -(sp)
			lea		@str\@(pc), a0
			jsr		MDDBG__Console_\0
			move.l	(sp)+, a0
		endif

		move.w	(sp)+, sr
		bra.w	@instr_end\@
	@str\@:
		__FSTRING_GenerateDecodedString \1
		even
	@instr_end\@:

#ifndef MD-SHELL
	elseif strcmp("\0","run")|strcmp("\0","Run")
		jsr		MDDBG__ErrorHandler_ConsoleOnly
		jsr		\1
		bra.s	*

#endif
	elseif strcmp("\0","clear")|strcmp("\0","Clear")
		move.w	sr, -(sp)
		jsr		MDDBG__ErrorHandler_ClearConsole
		move.w	(sp)+, sr

	elseif strcmp("\0","pause")|strcmp("\0","Pause")
		move.w	sr, -(sp)
		jsr		MDDBG__ErrorHandler_PauseConsole
		move.w	(sp)+, sr

	elseif strcmp("\0","sleep")|strcmp("\0","Sleep")
		move.w	sr, -(sp)
		move.w	d0, -(sp)
		move.l	a0, -(sp)
		move.w	\1, d0
		subq.w	#1, d0
		bcs.s	@sleep_done\@
		@sleep_loop\@:
			jsr		MDDBG__VSync
			dbf		d0, @sleep_loop\@

	@sleep_done\@:
		move.l	(sp)+, a0
		move.w	(sp)+, d0
		move.w	(sp)+, sr

	elseif strcmp("\0","setxy")|strcmp("\0","SetXY")
		move.w	sr, -(sp)
		movem.l	d0-d1, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		jsr		MDDBG__Console_SetPosAsXY_Stack
		addq.w	#4, sp
		movem.l	(sp)+, d0-d1
		move.w	(sp)+, sr

	elseif strcmp("\0","breakline")|strcmp("\0","BreakLine")
		move.w	sr, -(sp)
		jsr		MDDBG__Console_StartNewLine
		move.w	(sp)+, sr

	else
		inform	2,"""\0"" isn't a member of ""Console"""

	endif
	endm

; ---------------------------------------------------------------
; KDebug integration interface
; ---------------------------------------------------------------

KDebug &
	macro

#ifndef MD-SHELL
	if def(__DEBUG__)	; KDebug interface is only available in DEBUG builds
#endif
	if strcmp("\0","write")|strcmp("\0","writeline")|strcmp("\0","Write")|strcmp("\0","WriteLine")
		move.w	sr, -(sp)

		__FSTRING_GenerateArgumentsCode \1

		; If we have any arguments in string, use formatted string function ...
		if (__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		@str\@(pc), a1
			jsr		MDDBG__KDebug_\0\_Formatted
			movem.l	(sp)+, a0-a2/d7
			if (__sp>8)
				lea		__sp(sp), sp
			elseif (__sp>0)
				addq.w	#__sp, sp
			endif

		; ... Otherwise, use direct write as an optimization
		else
			move.l	a0, -(sp)
			lea		@str\@(pc), a0
			jsr		MDDBG__KDebug_\0
			move.l	(sp)+, a0
		endif

		move.w	(sp)+, sr
		bra.w	@instr_end\@
	@str\@:
		__FSTRING_GenerateDecodedString \1
		even
	@instr_end\@:

	elseif strcmp("\0","breakline")|strcmp("\0","BreakLine")
		move.w	sr, -(sp)
		jsr		MDDBG__KDebug_FlushLine
		move.w	(sp)+, sr

	elseif strcmp("\0","starttimer")|strcmp("\0","StartTimer")
		move.w	sr, -(sp)
		move.w	#$9FC0, ($C00004).l
		move.w	(sp)+, sr

	elseif strcmp("\0","endtimer")|strcmp("\0","EndTimer")
		move.w	sr, -(sp)
		move.w	#$9F00, ($C00004).l
		move.w	(sp)+, sr

	elseif strcmp("\0","breakpoint")|strcmp("\0","BreakPoint")
		move.w	sr, -(sp)
		move.w	#$9D00, ($C00004).l
		move.w	(sp)+, sr

	else
		inform	2,"""\0"" isn't a member of ""KDebug"""

	endif
#ifndef MD-SHELL
	endif
#endif
	endm

; ---------------------------------------------------------------
__ErrorMessage &
	macro	string, opts
		__FSTRING_GenerateArgumentsCode \string
		jsr		MDDBG__ErrorHandler
		__FSTRING_GenerateDecodedString \string
		if DEBUGGER__EXTENSIONS__ENABLE
			dc.b	\opts+_eh_return|(((*&1)^1)*_eh_align_offset)	; add flag "_eh_align_offset" if the next byte is at odd offset ...
			even													; ... to tell Error handler to skip this byte, so it'll jump to ...
			jmp		MDDBG__ErrorHandler_PagesController				; ... extensions controller
		else
			dc.b	\opts+0
			even
		endif
	endm

; ---------------------------------------------------------------
__FSTRING_GenerateArgumentsCode &
	macro	string

	__pos:	set 	instr(\string,'%<')		; token position
	__stack:set		0						; size of actual stack
	__sp:	set		0						; stack displacement

	; Parse string itself
	while (__pos)

		; Retrive expression in brackets following % char
    	__endpos:	set		instr(__pos+1,\string,'>')
    	__midpos:	set		instr(__pos+5,\string,' ')
    	if (__midpos<1)|(__midpos>__endpos)
			__midpos: = __endpos
    	endif
		__substr:	substr	__pos+1+1,__endpos-1,\string			; .type ea param
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %(.w d0 hex) )
		if "\__type">>8="."
			__operand:	substr	__pos+1+1,__midpos-1,\string			; .type ea
			__param:	substr	__midpos+1,__endpos-1,\string			; param

			if "\__type"=".b"
				pushp	"move\__operand\,1(sp)"
				pushp	"subq.w	#2, sp"
				__stack: = __stack+2
				__sp: = __sp+2

			elseif "\__type"=".w"
				pushp	"move\__operand\,-(sp)"
				__stack: = __stack+1
				__sp: = __sp+2

			elseif "\__type"=".l"
				pushp	"move\__operand\,-(sp)"
				__stack: = __stack+1
				__sp: = __sp+4

			else
				fatal 'Unrecognized type in string operand: %<\__substr>'
			endif
		endif

		__pos:	set		instr(__pos+1,\string,'%<')
	endw

	; Generate stack code
	rept __stack
		popp	__command
		\__command
	endr

	endm

; ---------------------------------------------------------------
__FSTRING_GenerateDecodedString &
	macro string

	__lpos:	set		1						; start position
	__pos:	set 	instr(\string,'%<')		; token position

	while (__pos)

		; Write part of string before % token
		__substr:	substr	__lpos,__pos-1,\string
		dc.b	"\__substr"

		; Retrive expression in brakets following % char
    	__endpos:	set		instr(__pos+1,\string,'>')
    	__midpos:	set		instr(__pos+5,\string,' ')
    	if (__midpos<1)|(__midpos>__endpos)
			__midpos: = __endpos
    	endif
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %<.w d0 hex> )
		if "\__type">>8="."    
			__param:	substr	__midpos+1,__endpos-1,\string			; param
			
			; Validate format setting ("param")
			if strlen("\__param")<1
				__param: substr ,,"hex"			; if param is ommited, set it to "hex"
			elseif strcmp("\__param","signed")
				__param: substr ,,"hex+signed"	; if param is "signed", correct it to "hex+signed"
			endif

			if (\__param < $80)
				inform	2,"Illegal operand format setting: ""\__param\"". Expected ""hex"", ""dec"", ""bin"", ""sym"", ""str"" or their derivatives."
			endif

			if "\__type"=".b"
				dc.b	\__param
			elseif "\__type"=".w"
				dc.b	\__param|1
			else
				dc.b	\__param|3
			endif

		; Expression is an inline constant (e.g. %<endl> )
		else
			__substr:	substr	__pos+1+1,__endpos-1,\string
			dc.b	\__substr
		endif

		__lpos:	set		__endpos+1
		__pos:	set		instr(__pos+1,\string,'%<')
	endw

	; Write part of string before the end
	__substr:	substr	__lpos,,\string
	dc.b	"\__substr"
	dc.b	0

	endm