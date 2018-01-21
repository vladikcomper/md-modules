
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Format String testing module
; ---------------------------------------------------------------

	include "MDShell-v1.asm"

; ---------------------------------------------------------------
	jmp		Main(pc)				; entry point
; ---------------------------------------------------------------

	include	"..\..\core\Symbols.asm"
	include	"..\..\core\Formatter - Sym.asm"
	include	"..\..\core\Formatter - Bin.asm"
	include	"..\..\core\Formatter - Dec.asm"
	include	"..\..\core\Formatter - Hex.asm"
	include	"..\..\core\Format String.asm"

; ---------------------------------------------------------------
Main:
	lea		$FF0000, a0

	lea		@TestsData(pc), a6		; a6 = tests data
	lea		$FF0000, a5				; a5 = string buffer
	moveq	#0, d1					; d1 will be tests counter

	@RunTest:
		Console.Write <color|fgWhite,'Test #', hex, '... '>, { <.b d1> }

		moveq	#0, d4
		move.b	(a6)+, d4				; d4 = source string size

		lea		(a5), a0				; a0 = buffer
		lea		(a6), a1				; a1 = source string
		move.l	#$89ABCDEF, -(sp)		; push arguments to the stack ...
		move.l	#$01234567, -(sp)		; ''
		move.w	#1234, -(sp)			; ''
                                              
		moveq	#$20-1, d7				; d7 = string buffer size -1
		lea		(sp), a2
		lea		@IdleFlush(pc), a4
		jsr		FormatString

		lea		$A(sp), sp				; restore stack ...

		add.w	d4, a6					; jump over the source string to get the resulting string ...
		moveq	#0, d4
		move.b	(a6)+, d4				; d4 = correctly formatted output size
		lea		(a6), a1				; a1 = correct
										; a5 = actual
		adda.w	d4, a6					; a6 = pointer to the next test ...

		sub.l	a5, a0	
		move.w	a0, d3					; d3 = actual output size
		cmp.w	d3, d4
		bne		@SizeMismatch

		subq.w	#1, d4

		@compare_loop:
			cmpm.b	(a1)+,(a5)+
			bne.s	@ByteMismatch
			dbf		d4, @compare_loop

		Console.Write <color|fgGreen,'OK', endl>

	@NextTest:
		addq.w	#1, d1
		tst.b	(a6)
		bne	@RunTest
		rts

	@SizeMismatch:
		Console.Write <color|fgRed,'Size mismatch (',hex,'<>',hex,')', endl>, { <.b d3>, <.b d4> }
		bra	@NextTest

	@ByteMismatch:
		Console.Write <color|fgRed,'Byte mismatch (',hex,'<>',hex,')', endl>, { <.b -1(a1)>, <.b -1(a5)> }
		bra	@NextTest

	rts

; --------------------------------------------------------------
; Buffer flush function
; --------------------------------------------------------------

@IdleFlush:
	addq.w	#8, d7				; set Carry flag, so FormatString is terminated after this flush
	rts

; --------------------------------------------------------------
dcs	macro
		dc.b	@end\@-@start\@
	@start\@:
		dc.b	\_
	@end\@:
	endm

@TestsData:

	; NOTICE: Null-terminator is not included in the output string compared here.
	;	While FormatString *does* add null-ternimator, returned buffer position
	;	points *before* null-terminator, not *after* it (if no overflows occured).
	
	; TODOh: Replace numbers with literal constants ...

	; #00: Simple test
	dcs.b	'Simple string',$00			; source string
	dcs.b	'Simple string'				; correctly formatted output
	
	; #01: Size limit test #1 ($20 bytes)
	dcs.b	'This string might overflow the buffer!',$00
	dcs.b	'This string might overflow the b'

	; #02: Size limit test #2
	dcs.b	'This string might overflow the b',$00
	dcs.b	'This string might overflow the b'

	; #03: Size limit test #3
	dcs.b	'This string might overflow the ',$00
	dcs.b	'This string might overflow the '

	; #04: Formatters test #1
	dcs.b	$91,$83,$83,$00
	dcs.b	'12340123456789ABCDEF'

	; #05: Formatters test #2
	dcs.b	$91,' ',$83,' ',$83,$00
	dcs.b	'1234 01234567 89ABCDEF';,$00

	; #06: Formatters test #3
	dcs.b	'--',$91,' ',$83,' ',$83,'--',$00
	dcs.b	'--1234 01234567 89ABCDEF--';,$00

	; #07: Size limit + formatters test #1
	dcs.b	'--------',$91,' ',$83,' ',$83,'--',$00
	dcs.b	'--------1234 01234567 89ABCDEF--'

	; #08: Size limit + formatters test #2
	dcs.b	'----------',$91,' ',$83,' ',$83,'--',$00
	dcs.b	'----------1234 01234567 89ABCDEF'

	; #09: Size limit + formatters test #3
	dcs.b	'-----------',$91,' ',$83,' ',$83,'--',$00
	dcs.b	'-----------1234 01234567 89ABCDE'

	; #0A: Multiple formatters test
	dcs.b	$99,' ',$A0,' ',$88,$00
	dcs.b	'+1234 00100011 +67'

	dc.b	0
	even

; --------------------------------------------------------------
; Symbols table should be included here
; --------------------------------------------------------------

SymbolData:
	
	dc.w	-1			; pad 2 bytes to avoid interfering with MDShell's automatic symbol table
