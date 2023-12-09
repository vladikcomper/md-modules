	if def(_KDEBUG_DEFS)=0
_KDEBUG_DEFS:	equ	1

; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; KDebug intergration module (definitions only)
;
; NOTICE: This defines ASM68K-only macros and partially
; duplicates shared macro definitions from higher-level bundles.
; However, this allows to use `KDebug` macros inside the
; debugger itself.
; ---------------------------------------------------------------

KDebug &
	macro

	if def(__DEBUG__)	; KDebug interface is only available in DEBUG builds
	if strcmp("\0","write")|strcmp("\0","writeline")|strcmp("\0","Write")|strcmp("\0","WriteLine")
		move.w	sr, -(sp)
		__FSTRING_GenerateArgumentsCode \1
		movem.l	a0-a2/d7, -(sp)
		if (__sp>0)
			lea		4*4(sp), a2
		endc
		lea		@str\@(pc), a1
		jsr		KDebug_\0\_Formatted
		movem.l	(sp)+, a0-a2/d7
		if (__sp>8)
			lea		__sp(sp), sp
		elseif (__sp>0)
			addq.w	#__sp, sp
		endc
		move.w	(sp)+, sr
		bra.w	@instr_end\@
	@str\@:
		__FSTRING_GenerateDecodedString \1
		even
	@instr_end\@:

	elseif strcmp("\0","breakline")|strcmp("\0","BreakLine")
		move.w	sr, -(sp)
		jsr		KDebug_FlushLine
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

	endc
	endc
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
    	endc
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
			endc
		endc

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
    	endc
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %<.w d0 hex> )
		if "\__type">>8="."    
			__param:	substr	__midpos+1,__endpos-1,\string			; param
			
			; Validate format setting ("param")
			if strlen("\__param")<1
				__param: substr ,,"hex"			; if param is ommited, set it to "hex"
			elseif strcmp("\__param","signed")
				__param: substr ,,"hex+signed"	; if param is "signed", correct it to "hex+signed"
			endc

			if (\__param < $80)
				inform	2,"Illegal operand format setting: ""\__param\"". Expected ""hex"", ""dec"", ""bin"", ""sym"", ""str"" or their derivatives."
			endc

			if "\__type"=".b"
				dc.b	\__param
			elseif "\__type"=".w"
				dc.b	\__param|1
			else
				dc.b	\__param|3
			endc

		; Expression is an inline constant (e.g. %<endl> )
		else
			__substr:	substr	__pos+1+1,__endpos-1,\string
			dc.b	\__substr
		endc

		__lpos:	set		__endpos+1
		__pos:	set		instr(__pos+1,\string,'%<')
	endw

	; Write part of string before the end
	__substr:	substr	__lpos,,\string
	dc.b	"\__substr"
	dc.b	0

	endm

	endc