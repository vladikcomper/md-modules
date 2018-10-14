
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Format String testing module
; ---------------------------------------------------------------

	include "MDShell-v11.asm"

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

		lea		(sp), a3
		move.w	(a6)+, d4
		beq.s	@args_done
		sub.w	d4, sp   
		lea		(sp), a3
		lsr.w	d4
		subq.w	#1, d4
		
		@args_loop:
			move.w	(a6)+, (a3)+
			dbf		d4, @args_loop
		
		@args_done:

		moveq	#0, d4
		move.b	(a6)+, d4				; d4 = source string size

		lea		(a5), a0				; a0 = buffer
		lea		(a6), a1				; a1 = source string
                                              
		moveq	#$20-1, d7				; d7 = string buffer size -1
		lea		(sp), a2
		lea		@IdleFlush(pc), a4
		jsr		FormatString

		lea		(a3), sp				; restore stack pointer

		add.w	d4, a6					; jump over the source string to get the resulting string ...
		moveq	#0, d4
		move.b	(a6)+, d4				; d4 = correctly formatted output size
		lea		(a6), a1				; a1 = correct
										; a5 = actual
										
		lea		(a5), a2				; a2 = got
		lea		(a1), a3				; a3 = expected
		
		adda.w	d4, a6					; a6 = pointer to the next test ...
		move.l	a6, d0
		addq.w	#1, d0
		and.w	#-2, d0
		movea.l	d0, a6

		sub.l	a5, a0	
		move.w	a0, d3					; d3 = actual output size  
		cmp.w	d3, d4
		bne		@SizeMismatch

		subq.w	#1, d4
		bmi.w	@GenericError

		@compare_loop:
			cmpm.b	(a1)+, (a5)+
			bne.w	@ByteMismatch
			dbf		d4, @compare_loop

		Console.Write <color|fgGreen,'PASSED', endl>

	@NextTest:
		addq.w	#1, d1
		tst.w	(a6)
		bpl.w	@RunTest
		
		Console.Write <color|fgGreen,'ALL TESTS PASSED SUCCESSFULLY', endl>
		rts
		
	@TestFailure:
		Console.Write <color|fgWhite, 'Got:', endl, color|fgGrey, '"', str, '"', endl, color|fgWhite, 'Expected:', endl, color|fgGrey, '"', str, '"', endl >, { <.l a2>, <.l a3> }
		Console.Write <color|fgRed,'TEST FAILURE, STOPPING', endl>
		rts

	@SizeMismatch:
		Console.Write <color|fgRed,'FAILED', endl, 'Error: Size mismatch (',hex,'<>',hex,')', endl>, { <.b d3>, <.b d4> }
		bra	@TestFailure

	@ByteMismatch:
		Console.Write <color|fgRed,'FAILED', endl, 'Error: Byte mismatch (',hex,'<>',hex,')', endl>, { <.b -1(a1)>, <.b -1(a5)> }
		bra	@TestFailure
		
	@GenericError:
		Console.Write <color|fgRed,'FAILED', endl, 'Error: General failure', endl>
		bra	@TestFailure

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
		dc.b	\1
	@end\@:
	endm
	
addTest macro args,source_str,compare_str
	dc.w	(@stack_end\@-@stack_beg\@)

@stack_beg\@:
	rept narg(args)
		dc\args
		shift args
	endr
@stack_end\@:	

	dcs	<\source_str>
	dcs <\compare_str>
	even
	
@test_end\@:
	endm
	

@TestsData:

	; NOTICE: Null-terminator is not included in the output string compared here.
	;	While FormatString *does* add null-ternimator, returned buffer position
	;	points *before* null-terminator, not *after* it (if no overflows occured).
	
	; TODOh: Replace numbers with literal constants ...

	; #00: Simple test
	addTest { <.l 0> }, &
			<'Simple string',$00>, &
			<'Simple string'>
			
	; #01: Buffer limit test #1 ($20 bytes)
	addTest { <.l 0> }, &
			<'This string might overflow the buffer!',$00>, &
			<'This string might overflow the b'>
			
	; #02: Buffer limit test #2  
	addTest { <.l 0> }, &
			<'This string might overflow the b',$00>, &
			<'This string might overflow the b'>

	; #03: Buffer limit test #3               
	addTest { <.l 0> }, &
			<'This string might overflow the ',$00>, &
			<'This string might overflow the '>
			
	; #04: Formatters test #1              
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<$91,$83,$83,$00>, &
			<'12340123456789ABCDEF'>

	; #05: Formatters test #2               
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<$91,' ',$83,' ',$83,$00>, &
			<'1234 01234567 89ABCDEF'>

	; #06: Formatters test #3            
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'--',$91,' ',$83,' ',$83,'--',$00>, &
			<'--1234 01234567 89ABCDEF--'>

	; #07: Buffer limit + formatters test #1  
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'--------',$91,' ',$83,' ',$83,'--',$00>, &
			<'--------1234 01234567 89ABCDEF--'>   
			
	; #08: Buffer limit + formatters test #2         
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'----------',$91,' ',$83,' ',$83,'--',$00>, &
			<'----------1234 01234567 89ABCDEF'>   

	; #09: Buffer limit + formatters test #3   
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<'-----------',$91,' ',$83,' ',$83,'--',$00>, &
			<'-----------1234 01234567 89ABCDE'>   

	; #0A: Multiple formatters test     
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<$99,' ',$A0,' ',$88,$00>, &
			<'+1234 00100011 +67'>
								
	; #0B: String decoding test #1
	addTest { <.l @SampleString1> }, &
			<$D0,$00>, &
			<'<String insertion test>'>
			
	; #0C: Buffer limit + String decoding test #1
	addTest { <.l @SampleString1>, <.l @SampleString1> }, &
			<$D0,$D0,$00>, &
			<'<String insertion test><String i'>
			
	; #0D: Buffer limit + String decoding test #2
	addTest { <.l @SampleString2> }, &
			<$D0,$00>, &
			<'This string takes all the buffer'>
			
	; #0E: Buffer limit + String decoding test #3
	addTest { <.l @SampleString2>, <.l @SampleString2> }, &
			<$D0,$D0,$00>, &
			<'This string takes all the buffer'>
			
	; #0F: Zero-length string decoding test #1
	addTest { <.l @EmptyString> }, &
			<'[',$D0,']',$00>, &
			<'[]'>
						
	; #10: Zero-length string decoding test #2
	addTest { <.l @EmptyString>, <.l @EmptyString>, <.l @EmptyString>, <.l @EmptyString> }, &
			<$D0,$D0,'-',$D0,$D0,$00>, &
			<'-'>
			
	; #11: Zero-length string decoding test #3
	addTest { <.l @EmptyString>, <.l @EmptyString> }, &
			<'[',$D0,$D0,']',$00>, &
			<'[]'>
	
	; #12: Character decoding test #1
	addTest { <.l @OneCharacterString> }, &
			<$D0,$00>, &
			<'a'>
			
	; #13: Character decoding test #2
	addTest { <.l @OneCharacterString>, <.l @OneCharacterString> }, &
			<$D0,$D0,$00>, &
			<'aa'>
			
	; #14: Buffer limit + Character decoding test #1
	addTest { <.l @OneCharacterString> }, &
			<'This string takes all the buffer',$D0,$00>, &
			<'This string takes all the buffer'>
			
	; #15: Buffer limit + Character decoding test #2
	addTest { <.l @OneCharacterString> }, &
			<'This string takes almost all ..',$D0,$00>, &
			<'This string takes almost all ..a'>    
			
	; #16: Buffer limit + Character decoding test #3
	addTest { <.l @OneCharacterString>, <.l @OneCharacterString> }, &
			<'This string takes almost all ..',$D0,$D0,$00>, &
			<'This string takes almost all ..a'>
			
	; #17: Buffer limit + Character decoding test #4
	addTest { <.l @OneCharacterString> }, &
			<'This string takes almost all ..',$D0,'!',$00>, &
			<'This string takes almost all ..a'>
			
	dc.w	-1
	 
; --------------------------------------------------------------
@SampleString1:
	dc.b	'<String insertion test>',0
	
@SampleString2:
	dc.b	'This string takes all the buffer',0
	
@EmptyString:
	dc.b	0
	
@OneCharacterString:
	dc.b	'a',0
	
	even

; --------------------------------------------------------------
; Symbols table should be included here
; --------------------------------------------------------------

SymbolData:
	
	dc.w	-1			; pad 2 bytes to avoid interfering with MDShell's automatic symbol table
