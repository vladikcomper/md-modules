
; ---------------------------------------------------------------
; WARNING! This disables automatic padding in order to combine DC.B's correctly
;	Make sure your code doesn't rely on padding (enabled by default)!
; ---------------------------------------------------------------

	padding off
	supmode on				; bypass warnings on privileged instructions

; ---------------------------------------------------------------
; Creates assertions for debugging
; ---------------------------------------------------------------
; EXAMPLES:
;	assert.b	d0, eq, #1		; d0 must be $01, or else crash
;	assert.w	d5, pl			; d5 must be positive
;	assert.l	a1, hi, a0		; assert a1 > a0, or else crash
;	assert.b	(MemFlag).w, ne	; MemFlag must be set (non-zero)
;	assert.l	a0, eq, #Obj_Player, MyObjectsDebugger
;
; NOTICE:
;	All "assert" saves and restores CCR so it's fully safe
;	to use in-between any instructions.
;	Use "_assert" instead if you deliberatly want to disbale
;	this behavior and safe a few cycles.
; ---------------------------------------------------------------

assert	macro	src, cond, dest, consoleprogram
#ifndef MD-SHELL
	; Assertions only work in DEBUG builds
	ifdef __DEBUG__
#endif
		move.w	sr, -(sp)
		_assert.ATTRIBUTE	src, cond, dest, consoleprogram
		move.w	(sp)+, sr
#ifndef MD-SHELL
	endif
#endif
		endm

; Same as "assert", but doesn't save/restore CCR (can be used to save a few cycles)
_assert	macro	src, cond, dest, consoleprogram
#ifndef MD-SHELL
	; Assertions only work in DEBUG builds
	ifdef __DEBUG__
#endif
		if "dest"<>""
			cmp.ATTRIBUTE	dest, src
		else
			tst.ATTRIBUTE	src
		endif

		switch lowstring("cond")
		case "eq"
			beq	.skip
		case "ne"
			bne	.skip
		case "cs"
			bcs	.skip
		case "cc"
			bcc	.skip
		case "pl"
			bpl	.skip
		case "mi"
			bmi	.skip
		case "hi"
			bhi	.skip
		case "hs"
			bhs	.skip
		case "ls"
			bls	.skip
		case "lo"
			blo	.skip
		case "gt"
			bgt	.skip
		case "ge"
			bge	.skip
		case "le"
			ble	.skip
		case "lt"
			blt	.skip
		elsecase
			!error "Unknown condition cond"
		endcase

	if "dest"<>""
		RaiseError	"Assertion failed:%<endl>%<pal2>> assert.ATTRIBUTE %<pal0>src,%<pal2>cond%<pal0>,dest%<endl>%<pal1>Got: %<.ATTRIBUTE src>", consoleprogram
	else
		RaiseError	"Assertion failed:%<endl>%<pal2>> assert.ATTRIBUTE %<pal0>src,%<pal2>cond%%<endl>%<pal1>Got: %<.ATTRIBUTE src>", consoleprogram
	endif

	.skip:
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

RaiseError	macro	string, consoleprogram, opts
	pea		*(pc)
	move.w	sr, -(sp)
	__FSTRING_GenerateArgumentsCode string
	jsr		MDDBG__ErrorHandler
	__FSTRING_GenerateDecodedString string
	if ("consoleprogram"<>"")			; if console program offset is specified ...
		.__align_flag:	set	((((*)&1)!1)*_eh_align_offset)
		if "opts"<>""
			dc.b	opts+_eh_enter_console|.__align_flag					; add flag "_eh_align_offset" if the next byte is at odd offset ...
		else
			dc.b	_eh_enter_console|.__align_flag						; ''
		endif
		!align	2													; ... to tell Error handler to skip this byte, so it'll jump to ...
		if DEBUGGER__EXTENSIONS__ENABLE
			jsr		consoleprogram										; ... an aligned "jsr" instruction that calls console program itself
			jmp		MDDBG__ErrorHandler_PagesController
		else
			jmp		consoleprogram										; ... an aligned "jmp" instruction that calls console program itself
		endif
	else
		if DEBUGGER__EXTENSIONS__ENABLE
			.__align_flag:	set	((((*)&1)!1)*_eh_align_offset)
			if "opts"<>""
				dc.b	opts+_eh_return|.__align_flag					; add flag "_eh_align_offset" if the next byte is at odd offset ...
			else
				dc.b	_eh_return|.__align_flag							; add flag "_eh_align_offset" if the next byte is at odd offset ...
			endif
			!align	2													; ... to tell Error handler to skip this byte, so it'll jump to ...
			jmp		MDDBG__ErrorHandler_PagesController
		else
			dc.b	opts+0						; otherwise, just specify \opts for error handler, +0 will generate dc.b 0 ...
			!align	2							; ... in case \opts argument is empty or skipped
		endif
	endif
	!align	2
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
;	Console.WriteLine "Your data is %<.b d0>"
;	Console.WriteLine "%<pal0>Your code pointer: %<.l a0 sym>"
;	Console.SetXY #1, #4
;	Console.SetXY d0, d1
;	Console.Sleep #60 ; sleep for 1 second
;	Console.Pause
;
; NOTICE:
;	All "Console.*" calls save and restore CCR so they are fully
;	safe to use in-between any instructions.
;	Use "_Console.*" instead if you deliberatly want to disbale
;	this behavior and safe a few cycles.
; ---------------------------------------------------------------

Console	macro	argument1, argument2
	switch lowstring("ATTRIBUTE")
	; "Console.Run" doesn't have to save/restore CCR, because it's a no-return
	case "run"
		_Console.ATTRIBUTE	argument1, argument2

	; Other Console calls do save/restore CCR
	elsecase
		move.w	sr, -(sp)
		_Console.ATTRIBUTE	argument1, argument2
		move.w	(sp)+, sr
	endcase
	endm

; Same as "Console", but doesn't save/restore CCR (can be used to save a few cycles)
_Console	macro	argument1, argument2
	switch lowstring("ATTRIBUTE")
	case "write"
		__FSTRING_GenerateArgumentsCode argument1

		; If we have any arguments in string, use formatted string function ...
		if (.__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		.__data(pc), a1
			jsr		MDDBG__Console_Write_Formatted
			movem.l	(sp)+, a0-a2/d7
			if (.__sp>8)
				lea		.__sp(sp), sp
			elseif (.__sp>0)
				addq.w	#.__sp, sp
			endif

		; ... Otherwise, use direct write as an optimization
		else
			move.l	a0, -(sp)
			lea		.__data(pc), a0
			jsr		MDDBG__Console_Write
			move.l	(sp)+, a0
		endif

		bra.w	.__leave
	.__data:
		__FSTRING_GenerateDecodedString argument1
		!align	2
	.__leave:

	case "writeline"
		__FSTRING_GenerateArgumentsCode argument1

		; If we have any arguments in string, use formatted string function ...
		if (.__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		.__data(pc), a1
			jsr		MDDBG__Console_WriteLine_Formatted
			movem.l	(sp)+, a0-a2/d7
			if (.__sp>8)
				lea		.__sp(sp), sp
			elseif (.__sp>0)
				addq.w	#.__sp, sp
			endif
		; ... Otherwise, use direct write as an optimization
		else
			move.l	a0, -(sp)
			lea		.__data(pc), a0
			jsr		MDDBG__Console_WriteLine
			move.l	(sp)+, a0
		endif
		bra.w	.__leave
	.__data:
		__FSTRING_GenerateDecodedString argument1
		!align	2
	.__leave:

#ifndef MD-SHELL
	case "run"
		jsr		MDDBG__ErrorHandler_ConsoleOnly
		jsr		argument1
		bra.s	*

#endif
	case "clear"
		jsr		MDDBG__ErrorHandler_ClearConsole

	case "pause"
		jsr		MDDBG__ErrorHandler_PauseConsole

	case "sleep"
		move.w	d0, -(sp)
		move.l	a0, -(sp)
		move.w	argument1, d0
		subq.w	#1, d0
		bcs.s	.__sleep_done
		.__sleep_loop:
			jsr		MDDBG__VSync
			dbf		d0, .__sleep_loop

	.__sleep_done:
		move.l	(sp)+, a0
		move.w	(sp)+, d0

	case "setxy"
		movem.l	d0-d1, -(sp)
		move.w	argument2, -(sp)
		move.w	argument1, -(sp)
		jsr		MDDBG__Console_SetPosAsXY_Stack
		addq.w	#4, sp
		movem.l	(sp)+, d0-d1

	case "breakline"
		jsr		MDDBG__Console_StartNewLine

	elsecase
		!error	"ATTRIBUTE isn't a member of Console"

	endcase
	endm

; ---------------------------------------------------------------
; KDebug integration interface
; ---------------------------------------------------------------
; EXAMPLES:
;	KDebug.WriteLine "Look in your debug console!"
;	KDebug.WriteLine "Your D0 is %<.w d0>"
;	KDebug.BreakPoint
;	KDebug.StartTimer
;	KDebug.EndTimer
;
; NOTICE:
;	All "KDebug.*" calls save and restore CCR so they are fully
;	safe to use in-between any instructions.
;	Use "_KDebug.*" instead if you deliberatly want to disbale
;	this behavior and safe a few cycles.
; ---------------------------------------------------------------

KDebug	macro	argument1
#ifndef MD-SHELL
	ifdef __DEBUG__	; KDebug interface is only available in DEBUG builds
#endif
		move.w	sr, -(sp)
		_KDebug.ATTRIBUTE	argument1
		move.w	(sp)+, sr
#ifndef MD-SHELL
	endif
#endif
	endm

; Same as "KDebug", but doesn't save/restore CCR (can be used to save a few cycles)
_KDebug	macro	argument1
#ifndef MD-SHELL
	ifdef __DEBUG__	; KDebug interface is only available in DEBUG builds
#endif
	switch lowstring("ATTRIBUTE")
	case "write"
		__FSTRING_GenerateArgumentsCode argument1

		; If we have any arguments in string, use formatted string function ...
		if (.__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		.__data(pc), a1
			jsr		MDDBG__KDebug_Write_Formatted
			movem.l	(sp)+, a0-a2/d7
			if (.__sp>8)
				lea		.__sp(sp), sp
			elseif (.__sp>0)
				addq.w	#.__sp, sp
			endif

		; ... Otherwise, use direct write as an optimization
		else
			move.l	a0, -(sp)
			lea		.__data(pc), a0
			jsr		MDDBG__KDebug_Write
			move.l	(sp)+, a0
		endif

		bra.w	.__leave
	.__data:
		__FSTRING_GenerateDecodedString argument1
		!align	2
	.__leave:

	case "writeline"
		__FSTRING_GenerateArgumentsCode argument1

		; If we have any arguments in string, use formatted string function ...
		if (.__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		.__data(pc), a1
			jsr		MDDBG__KDebug_WriteLine_Formatted
			movem.l	(sp)+, a0-a2/d7
			if (.__sp>8)
				lea		.__sp(sp), sp
			elseif (.__sp>0)
				addq.w	#.__sp, sp
			endif

		; ... Otherwise, use direct write as an optimization
		else
			move.l	a0, -(sp)
			lea		.__data(pc), a0
			jsr		MDDBG__KDebug_WriteLine
			move.l	(sp)+, a0
		endif

		bra.w	.__leave
	.__data:
		__FSTRING_GenerateDecodedString argument1
		!align	2
	.__leave:

	case "breakline"
		jsr		MDDBG__KDebug_FlushLine

	case "starttimer"
		move.w	#$9FC0, ($C00004).l

	case "endtimer"
		move.w	#$9F00, ($C00004).l

	case "breakpoint"
		move.w	#$9D00, ($C00004).l

	elsecase
		!error	"ATTRIBUTE isn't a member of KDebug"

	endcase
#ifndef MD-SHELL
	endif
#endif
	endm

; ---------------------------------------------------------------
__ErrorMessage  macro string, opts
		__FSTRING_GenerateArgumentsCode string
		jsr		MDDBG__ErrorHandler
		__FSTRING_GenerateDecodedString string

		if DEBUGGER__EXTENSIONS__ENABLE
		.__align_flag: set (((*)&1)!1)*_eh_align_offset
			dc.b	(opts)+_eh_return|.__align_flag	; add flag "_eh_align_offset" if the next byte is at odd offset ...
			!align	2												; ... to tell Error handler to skip this byte, so it'll jump to ...
			jmp		MDDBG__ErrorHandler_PagesController	; ... extensions controller
		else
			dc.b	(opts)+0
			!align	2
		endif
	endm

; ---------------------------------------------------------------
; WARNING: Since AS cannot compile instructions out of strings
;	we have to do lots of switch-case bullshit down here..

__FSTRING_PushArgument macro OPERAND,DEST

	.__operand:		set	OPERAND
	.__dval:		set	0

	; If OPERAND starts with "#", simulate "#immediate" mode by splitting OPERAND string
	if (substr(OPERAND, 0, 1)="#")
		.__dval:	set	VAL(substr(OPERAND, 1, 0))
		.__operand:	set	"#"

	; If OPERAND starts with "(" and ends with ").w", simulate "(XXX).w" mode
	elseif (strlen(OPERAND)>4)&&(substr(OPERAND, 0, 1)="(")&&(substr(OPERAND, strlen(OPERAND)-3, 3)=").w")
		.__dval:	set VAL(substr(OPERAND, 1, strlen(OPERAND)-4))
		.__operand:	set	"x.w"

	; If OPERAND starts with "(" and ends with ").l", simulate "(XXX).l" mode
	elseif (strlen(OPERAND)>4)&&(substr(OPERAND, 0, 1)="(")&&(substr(OPERAND, strlen(OPERAND)-3, 3)=").l")
		.__dval:	set VAL(substr(OPERAND, 1, strlen(OPERAND)-4))
		.__operand:	set	"x.l"

	; If OPERAND ends with "(pc)", simulate "d16(pc)" mode by splitting OPERAND string
	elseif (strlen(OPERAND)>4)&&(substr(OPERAND, strlen(OPERAND)-4, 4)="(pc)")
		.__dval:	set	VAL(substr(OPERAND, 0, strlen(OPERAND)-4))
		.__operand:	set substr(OPERAND, strlen(OPERAND)-4, 0)

	; If OPERAND ends with "(an)", simulate "d16(an)" mode by splitting OPERAND string
	elseif (strlen(OPERAND)>4)&&(substr(OPERAND, strlen(OPERAND)-4, 2)="(a")&&(substr(OPERAND, strlen(OPERAND)-1, 1)=")")
		.__dval:	set	VAL(substr(OPERAND, 0, strlen(OPERAND)-4))
		.__operand:	set substr(OPERAND, strlen(OPERAND)-4, 0)

	endif

	switch lowstring(.__operand)
	case "d0"
		move.ATTRIBUTE	d0,DEST
	case "d1"
		move.ATTRIBUTE	d1,DEST
	case "d2"
		move.ATTRIBUTE	d2,DEST
	case "d3"
		move.ATTRIBUTE	d3,DEST
	case "d4"
		move.ATTRIBUTE	d4,DEST
	case "d5"
		move.ATTRIBUTE	d5,DEST
	case "d6"
		move.ATTRIBUTE	d6,DEST
	case "d7"
		move.ATTRIBUTE	d7,DEST
	
	case "a0"
		move.ATTRIBUTE	a0,DEST
	case "a1"
		move.ATTRIBUTE	a1,DEST
	case "a2"
		move.ATTRIBUTE	a2,DEST
	case "a3"
		move.ATTRIBUTE	a3,DEST
	case "a4"
		move.ATTRIBUTE	a4,DEST
	case "a5"
		move.ATTRIBUTE	a5,DEST
	case "a6"
		move.ATTRIBUTE	a6,DEST

	case "(a0)"
		move.ATTRIBUTE	.__dval(a0),DEST
	case "(a1)"
		move.ATTRIBUTE	.__dval(a1),DEST
	case "(a2)"
		move.ATTRIBUTE	.__dval(a2),DEST
	case "(a3)"
		move.ATTRIBUTE	.__dval(a3),DEST
	case "(a4)"
		move.ATTRIBUTE	.__dval(a4),DEST
	case "(a5)"
		move.ATTRIBUTE	.__dval(a5),DEST
	case "(a6)"
		move.ATTRIBUTE	.__dval(a6),DEST

	case "x.w"
		move.ATTRIBUTE	(.__dval).w,DEST

	case "x.l"
		move.ATTRIBUTE	(.__dval).l,DEST

	case "(pc)"
		move.ATTRIBUTE	.__dval(pc),DEST

	case "#"
		move.ATTRIBUTE	#.__dval,DEST

	elsecase
	.__evaluated_operand: set VAL(OPERAND)
		move.ATTRIBUTE	.__evaluated_operand,DEST

	endcase
	endm

; ---------------------------------------------------------------
; WARNING! Incomplete!
__FSTRING_GenerateArgumentsCode macro string

	.__pos:	set 	strstr(string,"%<")		; token position
	.__sp:	set		0						; stack displacement
	.__str:	set		string

	; Parse string itself
	while (.__pos>=0)

    	; Find the last occurance "%<" in the string
    	while ( strstr(substr(.__str,.__pos+2,0),"%<")>=0 )
			.__pos: 	set		strstr(substr(.__str,.__pos+2,0),"%<")+.__pos+2
		endm
		.__substr:	set		substr(.__str,.__pos,0)

		; Retrive expression in brackets following % char
    	.__endpos:	set		strstr(.__substr,">")
		if (.__endpos<0) ; Fix bizzare AS bug as stsstr() fails to check the last character of string
			.__endpos:	set		strlen(.__substr)-1
		endif
    	.__midpos:	set		strstr(substr(.__substr,5,0)," ")
    	if ((.__midpos<0)||(.__midpos+5>.__endpos))
			.__midpos:	set		.__endpos
		else
			.__midpos:	set		.__midpos+5
    	endif
		.__type:		set		substr(.__substr,2,2)	; .type

		; Expression is an effective address (e.g. %(.w d0 hex) )
		if ((strlen(.__type)==2)&&(substr(.__type,0,1)=="."))
			.__operand:	set		substr(.__substr,5,.__midpos-5)						; ea
			.__param:	set		substr(.__substr,.__midpos+1,.__endpos-.__midpos-1)		; param

			if (.__type==".b")
				subq.w	#2, sp
				__FSTRING_PushArgument.b	.__operand,1(sp)
				.__sp:	set		.__sp+2

			elseif (.__type==".w")
				__FSTRING_PushArgument.w	.__operand,-(sp)
				.__sp:	set		.__sp+2

			elseif (.__type==".l")
				__FSTRING_PushArgument.l	.__operand,-(sp)
				.__sp:	set		.__sp+4

			else
				error "Unrecognized type in string operand: \{.__type}"
			endif

		endif

		; Cut string
		if (.__pos>0)
			.__str:	set		substr(.__str, 0, .__pos)
			.__pos:	set		strstr(.__str,"%<")
		else
			.__pos:	set		-1
		endif

	endm

	endm

; ---------------------------------------------------------------
__FSTRING_GenerateDecodedString macro string

	.__lpos:	set		0		; start position
	.__pos:	set		strstr(string, "%<")

	while (.__pos>=0)

		; Write part of string before % token
		if (.__pos-.__lpos>0)
			dc.b	substr(string, .__lpos, .__pos-.__lpos)
		endif

		; Retrive expression in brakets following % char
    	.__endpos:	set		strstr(substr(string,.__pos+1,0),">")+.__pos+1 
		if (.__endpos<=.__pos) ; Fix bizzare AS bug as stsstr() fails to check the last character of string
			.__endpos:	set		strlen(string)-1
		endif
    	.__midpos:	set		strstr(substr(string,.__pos+5,0)," ")+.__pos+5
    	if ((.__midpos<.__pos+5)||(.__midpos>.__endpos))
			.__midpos:	set		.__endpos
    	endif
		.__type:		set		substr(string,.__pos+1+1,2)		; .type

		; Expression is an effective address (e.g. %<.w d0 hex> )
		if ((strlen(.__type)==2)&&(substr(.__type,0,1)=="."))
			.__param:	set		substr(string,.__midpos+1,.__endpos-.__midpos-1)	; param

			; Validate format setting ("param")
			if (strlen(.__param)<1)
				.__param: 	set		"hex"			; if param is ommited, set it to "hex"
			elseif (.__param=="signed")
				.__param:	set		"hex+signed"	; if param is "signed", correct it to "hex+signed"
			endif

			if (val(.__param) < $80)
				!error "Illegal operand format setting: \{.__param}. Expected hex, dec, bin, sym, str or their derivatives."
			endif

			if (.__type==".b")
				dc.b	val(.__param)
			elseif (.__type==".w")
				dc.b	val(.__param)|1
			else
				dc.b	val(.__param)|3
			endif

		; Expression is an inline constant (e.g. %<endl> )
		else
			dc.b	val(substr(string,.__pos+1+1,.__endpos-.__pos-2))
		endif

		.__lpos:	set		.__endpos+1
		if (strstr(substr(string,.__pos+1,0),"%<")>=0)
			.__pos:	set		strstr(substr(string,.__pos+1,0), "%<")+.__pos+1
		else
			.__pos:	set		-1
		endif

	endm

	; Write part of string before the end
	dc.b	substr(string, .__lpos, 0), 0

	endm
