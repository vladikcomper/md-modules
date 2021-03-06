
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Format String testing module
; ---------------------------------------------------------------

	include "MDShell-v11.asm"

; ---------------------------------------------------------------
	jmp		(Main).l					; entry point
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Dummy labels for testing of offset decoding
;
; WARNING! All labels are rendered in lowercase, since
; ASM68K's symbol's file is unsed.
; ---------------------------------------------------------------

short_data_chunk:
	ds.b	$10				; $10 bytes

long_data_chunk:
	ds.b	$10001			; $10001 bytes
	even

; ---------------------------------------------------------------

	include	"..\..\core\Symbols.asm"
	include	"..\..\core\Formatter - Sym.asm"
	include	"..\..\core\Formatter - Bin.asm"
	include	"..\..\core\Formatter - Dec.asm"
	include	"..\..\core\Formatter - Hex.asm"
	include	"..\..\core\Format String.asm"

; ---------------------------------------------------------------
; Main routine
; ---------------------------------------------------------------

StringsBuffer = $FF0000
ArgumentsStack = $FFFF8000

_bufferSize = $20					; if you change this, you have to alter all the buffer overflow tests suites ...
_canaryValue = $DC					; an arbitrary byte value, written after the buffer to detect overflows

Main:
	Console.Write <color|fgWhite,'Running "FormatString" tests...', endl>

	lea		@TestsData(pc), a6		; a6 = tests data
	lea		StringsBuffer, a5		; a5 = string buffer
	moveq	#0, d1					; d1 will be tests counter

	@RunTest:
		lea		(a5), a0						; a0 = buffer
		movea.l	(a6), a1						; a1 = source string
		lea		$A(a6), a2						; a2 = arguments stack
		moveq	#_bufferSize-1, d7				; d7 = string buffer size -1
		lea		@IdleFlush(pc), a4
		move.b	#_canaryValue, _bufferSize(a5)	; write down canary value after the end of the buffer

		jsr		FormatString					; HERE'S OUR STAR LADIES AND GENTLEMEN !~  LET'S SEE HOW IT SURVIVES THE TEST

		cmp.b	#_canaryValue, _bufferSize(a5)	; make sure canary value didn't get overwritten ...
		bne.w	@BufferOverflow					; if it did, then writting past the end of the buffer is detected
		sf.b	_bufferSize(a5)					; add null-terminator past the end of the buffer, so strings are displayed correctly ...

		movea.l	4(a6), a1						; a1 = Compare string
		moveq	#0, d4
		move.b	(a1)+, d4						; d4 = correctly formatted output size

		lea		(a5), a2						; a2 = Got string
		lea		(a1), a3						; a3 = Expected string
		
		sub.l	a5, a0	
		move.w	a0, d3							; d3 = actual output size  
		cmp.w	d3, d4							; compare actual output size to the expected
		bne		@SizeMismatch					; if they don't match, branch

		subq.w	#1, d4
		bmi.w	@CompareStringCorrupted

		@compare_loop:
			cmpm.b	(a1)+, (a5)+
			bne.w	@ByteMismatch
			dbf		d4, @compare_loop

	@NextTest:
		addq.w	#1, d1							; increment test number
		adda.w	8(a6), a6						; a6 => Next test
		tst.w	(a6)							; is test header valid?
		bpl.w	@RunTest						; if yes, keep doing tests
		
	Console.Write <color|fgWhite,endl,'Number of completed tests: ',dec, endl>, { <.b d1> }
	Console.Write <color|fgGreen,'ALL TESTS HAVE PASSED SUCCESSFULLY', endl>
	rts

	; -------------------------------------------------------------------------		
	@PrintFailureHeader:
		Console.Write <color|fgRed,'Test #', dec, ' FAILED', endl>, { <.b d1> }
		rts

	; -------------------------------------------------------------------------		
	@PrintFailureDiff:
		Console.Write <color|fgWhite, 'Got:', endl, color|fgGrey, '"', str, '"', endl, color|fgWhite, 'Expected:', endl, color|fgGrey, '"', str, '"', endl >, { <.l a2>, <.l a3> }
		
	@HaltTests:
		Console.Write <color|fgRed,'TEST FAILURE, STOPPING', endl>
		rts

	; -------------------------------------------------------------------------		
	@BufferOverflow:
		bsr	@PrintFailureHeader
		Console.Write <color|fgRed,'Error: Writting past the end of buffer', endl>
		bra @HaltTests

	; -------------------------------------------------------------------------		
	@SizeMismatch:
		bsr	@PrintFailureHeader
		Console.Write <color|fgRed,'Error: Size mismatch (',hex,'<>',hex,')', endl>, { <.b d3>, <.b d4> }
		bra	@PrintFailureDiff

	; -------------------------------------------------------------------------		
	@ByteMismatch:
		bsr	@PrintFailureHeader
		Console.Write <color|fgRed,'Error: Byte mismatch (',hex,'<>',hex,')', endl>, { <.b -1(a1)>, <.b -1(a5)> }
		bra	@PrintFailureDiff
		
	; -------------------------------------------------------------------------		
	@CompareStringCorrupted:
		bsr	@PrintFailureHeader
		Console.Write <color|fgRed,'Error: Compare string corrupted', endl>
		bra	@PrintFailureDiff

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
		dc.b	0				; also put a null-terminator, so MDShell may print it as C-string also ...
	endm
	
addTest macro args,source_str,compare_str

@test_header\@:
	dc.l	@source_string\@						; (a6) => Source string absolute pointer
	dc.l	@compare_string\@						; 4(a6) => Compare string absolute pointer
	dc.w	@test_end\@-@test_header\@				; 8(a6)	=> End of test relative pointer

	rept narg(args)									; $A(a6) and on => Arguments stack
		dc\args
		shift args
	endr

@source_string\@:
	dc.b \source_str

@compare_string\@:
	dcs <\compare_str>								; this string also includes "length" byte for correct computations
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

	; #10: Multiple formatters test     
	addTest { <.w 1234>, <.l $01234567>, <.l $89ABCDEF> }, &
			<$99,' ',$A0,' ',$88,$00>, &
			<'+1234 00100011 +67'>
								
	; #11: String decoding test #1
	addTest { <.l @SampleString1> }, &
			<$D0,$00>, &
			<'<String insertion test>'>
			
	; #12: Buffer limit + String decoding test #1
	addTest { <.l @SampleString1>, <.l @SampleString1> }, &
			<$D0,$D0,$00>, &
			<'<String insertion test><String i'>
			
	; #13: Buffer limit + String decoding test #2
	addTest { <.l @SampleString2> }, &
			<$D0,$00>, &
			<'This string takes all the buffer'>
			
	; #14: Buffer limit + String decoding test #3
	addTest { <.l @SampleString2>, <.l @SampleString2> }, &
			<$D0,$D0,$00>, &
			<'This string takes all the buffer'>
			
	; #15: Zero-length string decoding test #1
	addTest { <.l @EmptyString> }, &
			<'[',$D0,']',$00>, &
			<'[]'>
						
	; #16: Zero-length string decoding test #2
	addTest { <.l @EmptyString>, <.l @EmptyString>, <.l @EmptyString>, <.l @EmptyString> }, &
			<$D0,$D0,'-',$D0,$D0,$00>, &
			<'-'>
			
	; #17: Zero-length string decoding test #3
	addTest { <.l @EmptyString>, <.l @EmptyString> }, &
			<'[',$D0,$D0,']',$00>, &
			<'[]'>
	
	; #18: Character decoding test #1
	addTest { <.l @OneCharacterString> }, &
			<$D0,$00>, &
			<'a'>
			
	; #19: Character decoding test #2
	addTest { <.l @OneCharacterString>, <.l @OneCharacterString> }, &
			<$D0,$D0,$00>, &
			<'aa'>
			
	; #20: Buffer limit + Character decoding test #1
	addTest { <.l @OneCharacterString> }, &
			<'This string takes all the buffer',$D0,$00>, &
			<'This string takes all the buffer'>
			
	; #21: Buffer limit + Character decoding test #2
	addTest { <.l @OneCharacterString> }, &
			<'This string takes almost all ..',$D0,$00>, &
			<'This string takes almost all ..a'>    
			
	; #22: Buffer limit + Character decoding test #3
	addTest { <.l @OneCharacterString>, <.l @OneCharacterString> }, &
			<'This string takes almost all ..',$D0,$D0,$00>, &
			<'This string takes almost all ..a'>
			
	; #23: Buffer limit + Character decoding test #4
	addTest { <.l @OneCharacterString> }, &
			<'This string takes almost all ..',$D0,'!',$00>, &
			<'This string takes almost all ..a'>

	; #24: Labels test #1
	addTest { <.l short_data_chunk> }, &
			<$B3,$00>, &
			<'short_data_chunk'>

	; #25: Labels test #2
	addTest { <.l short_data_chunk+1> }, &
			<$B3,$00>, &
			<'short_data_chunk+0001'>

	; #26: Labels test #3
	addTest { <.l long_data_chunk+$10001> }, &
			<$B3,$00>, &
			<'long_data_chunk+00010001'>

	; #27: Buffer limit + Lables test
	addTest { <.l long_data_chunk+$10001> }, &
			<'Overflow>>> ',$B3,$00>, &
			<'Overflow>>> long_data_chunk+0001'>

	; #28: Signed hex numbers test
	addTest { <.w $1234>, <.l -$01234567>, <.w $FFFF> }, &
			<$89,' ',$8B,' ',$89,$00>, &
			<'+1234 -01234567 -0001'>

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
