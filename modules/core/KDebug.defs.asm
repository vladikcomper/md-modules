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

; Default size of a text buffer used by `FormatString`, allocated
; on the stack.
; MD Debugger uses a smaller buffer, because the stack is usually
; quite busy by the time exception is thrown.
	if def(__KDEBUG_TEXT_BUFFER_SIZE__)=0
__KDEBUG_TEXT_BUFFER_SIZE__:	equ	$30
	endif


KDebug &
	macro

	if def(__DEBUG__)	; KDebug interface is only available in DEBUG builds
	if strcmp("\0","write")|strcmp("\0","writeline")|strcmp("\0","Write")|strcmp("\0","WriteLine")
		move.w	sr, -(sp)

		__FSTRING_GenerateArgumentsCode \1

		; If we have any arguments in string, use formatted string function ...
		if (__sp>0)
			movem.l	a0-a2/d7, -(sp)
			lea		4*4(sp), a2
			lea		@str\@(pc), a1
			jsr		KDebug_\0\_Formatted(pc)
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
			jsr		KDebug_\0(pc)
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
		jsr		KDebug_FlushLine(pc)
		move.w	(sp)+, sr

	elseif strcmp("\0","starttimer")|strcmp("\0","StartTimer")
		move.w	sr, -(sp)
		move.w	#$9FC0, VDP_Ctrl
		move.w	(sp)+, sr

	elseif strcmp("\0","endtimer")|strcmp("\0","EndTimer")
		move.w	sr, -(sp)
		move.w	#$9F00, VDP_Ctrl
		move.w	(sp)+, sr

	elseif strcmp("\0","breakpoint")|strcmp("\0","BreakPoint")
		move.w	sr, -(sp)
		move.w	#$9D00, VDP_Ctrl
		move.w	(sp)+, sr

	else
		inform	2,"""\0"" isn't a member of ""KDebug"""

	endif
	endif
	endm

	endif