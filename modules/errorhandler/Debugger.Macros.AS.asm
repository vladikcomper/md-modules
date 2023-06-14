
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
;	assert.b	d0, eq, #1		; d0 must be $01, or else crash!
;	assert.w	d5, eq			; d5 must be $0000!
;	assert.l	a1, hi, a0		; asert a1 > a0, or else crash!
;	assert.b	MemFlag, ne		; MemFlag must be non-zero!
; ---------------------------------------------------------------

assert	macro	SRC, COND, DEST
#ifndef MD-SHELL
	; Assertions only work in DEBUG builds
	ifdef __DEBUG__
#endif
		if "DEST"<>""
			cmp.ATTRIBUTE	DEST, SRC
		else
			tst.ATTRIBUTE	SRC
		endif

		switch "COND"
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
			!error "Unknown condition COND"
		endcase

		RaiseError	"Assertion failed:%<endl>SRC COND DEST"

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
	jsr		ErrorHandler
	__FSTRING_GenerateDecodedString string
	if ("consoleprogram"<>"")			; if console program offset is specified ...
		if "opts"<>""
			dc.b	opts+_eh_enter_console|((((*)&1)!1)*_eh_align_offset)		; add flag "_eh_align_offset" if the next byte is at odd offset ...
		else
			dc.b	_eh_enter_console|((((*)&1)!1)*_eh_align_offset)	; ''
		endif
		align	2															; ... to tell Error handler to skip this byte, so it'll jump to ...
		jmp		consoleprogram										; ... an aligned "jmp" instruction that calls console program itself
	else
		dc.b	opts+0						; otherwise, just specify \opts for error handler, +0 will generate dc.b 0 ...
		align	2							; ... in case \opts argument is empty or skipped
	endif
	align	2

	endm


; ---------------------------------------------------------------
; Console interface
; ---------------------------------------------------------------
; EXAMPLES:
;	Console.Run	YourConsoleProgram
;	Console.Write "Hello "
;	Console.WriteLine "...world!"
;	Console.SetXY #1, #4
;	Console.WriteLine "Your data is %<.b d0>"
;	Console.WriteLine "%<pal0>Your code pointer: %<.l a0 sym>"
; ---------------------------------------------------------------

Console	macro	argument1, argument2

	switch lowstring("ATTRIBUTE")
	case "write"
		move.w	sr, -(sp)
		__FSTRING_GenerateArgumentsCode argument1
		movem.l	a0-a2/d7, -(sp)
		lea		4*4(sp), a2
		lea		__data(pc), a1
		jsr		ErrorHandler___global__console_write_formatted
		movem.l	(sp)+, a0-a2/d7
		if (__sp>8)
			lea		__sp(sp), sp
		elseif (__sp>0)
			addq.w	#__sp, sp
		endif
		move.w	(sp)+, sr
		bra.w	__leave
	__data:
		__FSTRING_GenerateDecodedString argument1
		align	2
	__leave:

	case "writeline"
		move.w	sr, -(sp)
		__FSTRING_GenerateArgumentsCode argument1
		movem.l	a0-a2/d7, -(sp)
		lea		4*4(sp), a2
		lea		__data(pc), a1
		jsr		ErrorHandler___global__console_writeline_formatted
		movem.l	(sp)+, a0-a2/d7
		if (__sp>8)
			lea		__sp(sp), sp
		elseif (__sp>0)
			addq.w	#__sp, sp
		endif
		move.w	(sp)+, sr
		bra.w	__leave
	__data:
		__FSTRING_GenerateDecodedString argument1
		align	2
	__leave:

	case "run"
		jsr		ErrorHandler___extern__console_only
		jsr		argument1
		bra.s	*

	case "setxy"
		move.w	sr, -(sp)
		movem.l	d0-d1, -(sp)
		move.w	argument2, -(sp)
		move.w	argument1, -(sp)
		jsr		ErrorHandler___global__console_setposasxy_stack
		addq.w	#4, sp
		movem.l	(sp)+, d0-d1
		move.w	(sp)+, sr

	case "breakline"
		move.w	sr, -(sp)
		jsr		ErrorHandler___global__console_startnewline
		move.w	(sp)+, sr

	elsecase
		!error	"ATTRIBUTE isn't a member of Console"

	endcase
	endm

; ---------------------------------------------------------------
__ErrorMessage  macro string, opts
		__FSTRING_GenerateArgumentsCode string
		jsr		ErrorHandler
		__FSTRING_GenerateDecodedString string
		dc.b	opts+0
		align	2

	endm

; ---------------------------------------------------------------
; WARNING: Since AS cannot compile instructions out of strings
;	we have to do lots of switch-case bullshit down here..

__FSTRING_PushArgument macro OPERAND,DEST

	switch OPERAND
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
		move.ATTRIBUTE	(a0),DEST
	case "(a1)"
		move.ATTRIBUTE	(a1),DEST
	case "(a2)"
		move.ATTRIBUTE	(a2),DEST
	case "(a3)"
		move.ATTRIBUTE	(a3),DEST
	case "(a4)"
		move.ATTRIBUTE	(a4),DEST
	case "(a5)"
		move.ATTRIBUTE	(a5),DEST
	case "(a6)"
		move.ATTRIBUTE	(a6),DEST

	elsecase
		move.ATTRIBUTE	{OPERAND},DEST

	endcase
	endm

; ---------------------------------------------------------------
; WARNING! Incomplete!
__FSTRING_GenerateArgumentsCode macro string

	__pos:	set 	strstr(string,"%<")		; token position
	__sp:	set		0						; stack displacement
	__str:	set		string

	; Parse string itself
	while (__pos>=0)

    	; Find the last occurance "%<" in the string
    	while ( strstr(substr(__str,__pos+2,0),"%<")>=0 )
			__pos: 	set		strstr(substr(__str,__pos+2,0),"%<")+__pos+2
		endm
		__substr:	set		substr(__str,__pos,0)

		; Retrive expression in brackets following % char
    	__endpos:	set		strstr(__substr,">")
		if (__endpos<0) ; Fix bizzare AS bug as stsstr() fails to check the last character of string
			__endpos:	set		strlen(__substr)-1
		endif
    	__midpos:	set		strstr(substr(__substr,5,0)," ")
    	if ((__midpos<0)||(__midpos+5>__endpos))
			__midpos:	set		__endpos
		else
			__midpos:	set		__midpos+5
    	endif
		__type:		set		substr(__substr,2,2)	; .type

		; Expression is an effective address (e.g. %(.w d0 hex) )
		if ((strlen(__type)==2)&&(substr(__type,0,1)=="."))
			__operand:	set		substr(__substr,5,__midpos-5)						; ea
			__param:	set		substr(__substr,__midpos+1,__endpos-__midpos-1)		; param

			if (__type==".b")
				subq.w	#2, sp
				__FSTRING_PushArgument.b	__operand,1(sp)
				__sp:	set		__sp+2

			elseif (__type==".w")
				__FSTRING_PushArgument.w	__operand,-(sp)
				__sp:	set		__sp+2

			elseif (__type==".l")
				__FSTRING_PushArgument.l	__operand,-(sp)
				__sp:	set		__sp+4

			else
				error "Unrecognized type in string operand: \{__type}"
			endif

		endif

		; Cut string
		if (__pos>0)
			__str:	set		substr(__str, 0, __pos)
			__pos:	set		strstr(__str,"%<")
		else
			__pos:	set		-1
		endif

	endm

	endm

; ---------------------------------------------------------------
__FSTRING_GenerateDecodedString macro string

	__lpos:	set		0		; start position
	__pos:	set		strstr(string, "%<")

	while (__pos>=0)

		; Write part of string before % token
		if (__pos-__lpos>0)
			dc.b	substr(string, __lpos, __pos-__lpos)
		endif

		; Retrive expression in brakets following % char
    	__endpos:	set		strstr(substr(string,__pos+1,0),">")+__pos+1 
		if (__endpos<=__pos) ; Fix bizzare AS bug as stsstr() fails to check the last character of string
			__endpos:	set		strlen(string)-1
		endif
    	__midpos:	set		strstr(substr(string,__pos+5,0)," ")+__pos+5
    	if ((__midpos<__pos+5)||(__midpos>__endpos))
			__midpos:	set		__endpos
    	endif
		__type:		set		substr(string,__pos+1+1,2)		; .type

		; Expression is an effective address (e.g. %<.w d0 hex> )
		if ((strlen(__type)==2)&&(substr(__type,0,1)=="."))
			__param:	set		substr(string,__midpos+1,__endpos-__midpos-1)	; param

			; Validate format setting ("param")
			if (strlen(__param)<1)
				__param: 	set		"hex"			; if param is ommited, set it to "hex"
			elseif (__param=="signed")
				__param:	set		"hex+signed"	; if param is "signed", correct it to "hex+signed"
			endif

			if (val(__param) < $80)
				!error "Illegal operand format setting: \{__param}. Expected hex, dec, bin, sym, str or their derivatives."
			endif

			if (__type==".b")
				dc.b	val(__param)
			elseif (__type==".w")
				dc.b	val(__param)|1
			else
				dc.b	val(__param)|3
			endif

		; Expression is an inline constant (e.g. %<endl> )
		else
			dc.b	val(substr(string,__pos+1+1,__endpos-__pos-2))
		endif

		__lpos:	set		__endpos+1
		if (strstr(substr(string,__pos+1,0),"%<")>=0)
			__pos:	set		strstr(substr(string,__pos+1,0), "%<")+__pos+1
		else
			__pos:	set		-1
		endif

	endm

	; Write part of string before the end
	dc.b	substr(string, __lpos, 0), 0

	endm
