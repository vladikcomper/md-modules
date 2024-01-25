
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Format String testing module
; ---------------------------------------------------------------

	include "..\..\..\build\modules\mdshell\asm68k\MDShell.asm"

; ---------------------------------------------------------------

; Disable "__global" macro to avoid naming conflicts with MDShell
__NOGLOBALS__:	equ 1

	include	"..\..\core\Macros.asm"
	include	"..\..\core\Format_String.defs.asm"

	include	"..\..\core\Symbols.asm"
	include	"..\..\core\Formatter_Sym.asm"
	include	"..\..\core\Formatter_Bin.asm"
	include	"..\..\core\Formatter_Dec.asm"
	include	"..\..\core\Formatter_Hex.asm"
	include	"..\..\core\Format_String.asm"

; ---------------------------------------------------------------
; Main routine
; ---------------------------------------------------------------

StringsBuffer = $FF0000
ArgumentsStack = $FFFF8000

_bufferSize = $20					; if you change this, you have to alter all the buffer overflow tests suites ...
_canaryValue = $DC					; an arbitrary byte value, written after the buffer to detect overflows

Main:
	Console.WriteLine 'Running "FormatString" tests...'

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
		bmi.w	@NextTest

		@compare_loop:
			cmpm.b	(a1)+, (a5)+
			bne.w	@ByteMismatch
			dbf		d4, @compare_loop

	@NextTest:
		addq.w	#1, d1							; increment test number
		adda.w	8(a6), a6						; a6 => Next test
		tst.w	(a6)							; is test header valid?
		bpl.w	@RunTest						; if yes, keep doing tests
		
	Console.WriteLine 'Number of completed tests: %<.b d1 dec>'
	Console.WriteLine '%<pal1>ALL TESTS HAVE PASSED SUCCESSFULLY'
	rts

	; -------------------------------------------------------------------------		
	@PrintFailureHeader:
		Console.WriteLine '%<pal2>Test #%<.b d1 dec> FAILED'
		rts

	; -------------------------------------------------------------------------		
	@PrintFailureDiff:
		Console.WriteLine '%<pal0>Got:%<endl>%<pal2>"%<.l a2 str>"'
		Console.WriteLine '%<pal0>Expected:%<endl>%<pal2>"%<.l a3 str>"'
		
	@HaltTests:
		Console.WriteLine '%<pal1>TEST FAILURE, STOPPING'
		rts

	; -------------------------------------------------------------------------		
	@BufferOverflow:
		bsr	@PrintFailureHeader
		Console.WriteLine '%<pal1>Error: Writting past the end of buffer'
		bra @HaltTests

	; -------------------------------------------------------------------------		
	@SizeMismatch:
		bsr	@PrintFailureHeader
		Console.WriteLine '%<pal1>Error: Size mismatch (%<.b d3> != %<.b d4>)'
		bra	@PrintFailureDiff

	; -------------------------------------------------------------------------		
	@ByteMismatch:
		bsr	@PrintFailureHeader
		Console.WriteLine '%<pal1>Error: Byte mismatch (%<.b -1(a1)> != %<.b -1(a5)>)'
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
			<'short_data_chunk+1'>

	; #26: Labels test #3
	addTest { <.l long_data_chunk+$10001> }, &
			<$B3,$00>, &
			<'long_data_chunk+10001'>

	; #27: Buffer limit + Lables test
	addTest { <.l long_data_chunk+$10001> }, &
			<'Overflow>>> ',$B3,$00>, &
			<'Overflow>>> long_data_chunk+1000'>

	; #28: Signed hex numbers test
	addTest { <.w $1234>, <.l -$01234567>, <.w $FFFF> }, &
			<$89,' ',$8B,' ',$89,$00>, &
			<'+1234 -01234567 -0001'>

	; #29: Empty output test #1
	addTest { <.l 0> }, &
			<'',$00>, &
			<''>

	; #30: Empty output test #2
	addTest { <.l @EmptyString> }, &
			<$D0,$00>, &
			<''>

	; #31: Advanced symbol output test #1
	addTest { <.l $100> }, &
			<$B3,$00>, &
			<'Offset_100'>

	; #32: Advanced symbol output test #2
	addTest { <.l $101> }, &
			<$B3,$00>, &
			<'Offset_100+1'>

	; #33: Advanced symbol output test #3
	addTest { <.l $1FF> }, &
			<$B3,$00>, &
			<'Offset_100+FF'>

	; #34: Advanced symbol output test #4 (non-existent symbol)
	addTest { <.l 0> }, &
			<$B3,$00>, &
			<'00000000'>

	; #35: Advanced symbol output test #5 (non-existent symbol)
	addTest { <.l 0> }, &
			<$B7,$00>, &
			<'<unknown>'>

	; #36: Advanced symbol output test #6 (non-existent symbol)
	addTest { <.l $FF> }, &
			<$B3,$00>, &
			<'000000FF'>

	; #37: Advanced symbol output test #7 (non-existent symbol)
	addTest { <.l $FF> }, &
			<$B7,$00>, &
			<'<unknown>'>

	; #38: Advanced symbol output test #8 (far away symbol)
	addTest { <.l $20000> }, &
			<$B7,$00>, &
			<'long_data_chunk+FF80'>

	; #39: Advanced symbol output test #9 (far away symbol)
	addTest { <.l $20080> }, &
			<$B7,$00>, &
			<'long_data_chunk+10000'>

	; #40: Advanced symbol output test #10 (RAM addr)
	addTest { <.l $FF0000> }, &
			<$B3,$00>, &
			<'RAM_Offset_FF0000'>

	; #41: Advanced symbol output test #11 (RAM addr)
	addTest { <.l $FFFF0000> }, &
			<$B7,$00>, &
			<'RAM_Offset_FF0000'>

	; #42: Advanced symbol output test #12 (RAM addr)
	addTest { <.l $FFFF0001> }, &
			<$B3,$00>, &
			<'RAM_Offset_FF0000+1'>

	; #43: Advanced symbol output test #13 (RAM addr)
	addTest { <.l $FFFF0002> }, &
			<$B7,$00>, &
			<'RAM_Offset_FF0000+2'>

	; #44: Advanced symbol output test #10 (RAM addr #2)
	addTest { <.l $FF8000> }, &
			<$B3,$00>, &
			<'RAM_Offset_FFFF8000'>

	; #45: Advanced symbol output test #11 (RAM addr #2)
	addTest { <.w $8000> }, &
			<$B1,$00>, &
			<'RAM_Offset_FFFF8000'>

	; #46: Advanced symbol output test #12 (RAM addr #2)
	addTest { <.w $8001> }, &
			<$B1,$00>, &
			<'RAM_Offset_FFFF8000+1'>

	; #47: Advanced symbol output test #13 (RAM addr #3)
	addTest { <.w $FF> }, &
			<$B0,$00>, &
			<'RAM_End'>

	; #48: Symbol and displacement test #1
	addTest { <.l $1001> }, &
			<$B3+8,$C0,$00>, &
			<'ShouldOverflowBufferWithDis+1'>

	; #49: Symbol and displacement test #2
	addTest { <.l $1001> }, &
			<'>>>',$B3+8,$C0,'this is no longer visible!',$00>, &
			<'>>>ShouldOverflowBufferWithDis+1'>

	; #50: Symbol and displacement test #3
	addTest { <.l $1001> }, &
			<'>>>',$B3+8,'(',$C0,')',$00>, &
			<'>>>ShouldOverflowBufferWithDis(+'>

	; #51: Symbol and displacement test #4
	addTest { <.l $1000> }, &
			<$B3+8,'(',$C0,')',$00>, &
			<'ShouldOverflowBufferWithDis()'>

	; #52: Symbol and displacement test #5
	addTest { <.l $1003> }, &
			<'>>>>',$B3,$00>, &
			<'>>>>ShouldOverflowBufferWithDisp'>

	; #53: Symbol and displacement test #6
	addTest { <.l $1005> }, &
			<$B3,$00>, &
			<'ShouldOverflowBufferWithDisp2+1'>

	; #54: Symbol and displacement test #7
	addTest { <.l $1007> }, &
			<$B3,$00>, &
			<'ShouldOverflowBufferEvenWithoutD'>

	; #55: Symbol and displacement test #8
	addTest { <.l $1009> }, &
			<$B3,$00>, &
			<'ShouldOverflowBufferEvenWithoutD'>

	; #56: Symbol and displacement test #9
	addTest { <.l $100B> }, &
			<$B3,$00>, &
			<'ShouldOverflowBufferEvenWithoutD'>

	; #57: Symbol and displacement test #10
	addTest { <.l long_data_chunk+$10010> }, &
			<$B3,$00>, &
			<'long_data_chunk+10010'>

	; #58: Symbol and displacement test #11
	addTest { <.l long_data_chunk+$100010> }, &
			<$B3,$00>, &
			<'long_data_chunk+100010'>

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

short_data_chunk:	equ	$10000
long_data_chunk:	equ	$10080

; WARNING! Don't put anything after "SymbolData:"
