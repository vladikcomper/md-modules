
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Format String testing module
; ---------------------------------------------------------------

	include "_test\MDShell.asm"

; ---------------------------------------------------------------

jsr_test	macro	loc
	Console.Write "\loc\... "
	jsr		\loc
	Console.WriteLine "OK"
	endm


; ---------------------------------------------------------------
Main:
	jsr_test	MaskStackBoundaries_Tests
	jsr_test	GuessCallerTests

	Console.WriteLine "ALL DONE"
	rts

; ---------------------------------------------------------------
; Macro to implement assertions
; ---------------------------------------------------------------

assert	macro	src, cond, dest
	if narg=3
		cmp.\0	\dest, \src
	else narg=2
		tst.\0	\src
	endc
	b\cond\.s	@skip\@
	RaiseError	"Assertion failed:%<endl>\src \cond \dest"

@skip\@:
        endm

; ---------------------------------------------------------------
; Test "Error_MaskStackBoundaries"
; ---------------------------------------------------------------

MaskStackBoundaries_Tests:
	
	@stack_top:				equr	a1
	@stack_bottom:			equr	a2
	@stack_top_expected:	equr	a3
	@stack_bottom_expected:	equr	a4
	@test_func:				equr	a5
	@test_data:				equr	a6

	@test_cnt:				equr	d7

	@test_io:				reg		@stack_top-@stack_bottom_expected

	lea		Error_MaskStackBoundaries, @test_func
	lea		@TestData, @test_data
	moveq	#(@TestData_End-@TestData)/16-1, @test_cnt

	@RunTest:
		movem.l	(@test_data)+, @test_io
		jsr		(@test_func)
		assert.l	@stack_top, 	eq,	 @stack_top_expected
		assert.l	@stack_bottom, 	eq,	 @stack_bottom_expected
		dbf		@test_cnt, @RunTest

	rts

; ---------------------------------------------------------------
@TestData:
	;		Inputs					Expected output
	dc.l	$FF0000,	$FF0000,	$FF0000,	$FF0000
	dc.l	$FFFF0000,	$FFFF0000,	$FF0000,	$FF0000
	dc.l	$FFFF8000,	$FF0000,	$FF8000,	$FF0000
	dc.l	$FF0000,	$FFFF8000,	$FF0000,	$FF8000
	dc.l	$0,			$0,			$0,			$0

@TestData_End:

; ---------------------------------------------------------------
; Test "Error_GuessCaller"
; ---------------------------------------------------------------

GuessCallerTests:

	@stack_top:				equr	a1
	@stack_bottom:			equr	a2
	@test_func:				equr	a5
	@test_data:				equr	a6

	@stack_input:			reg		d0-d3
	@offset:				equr	d1
	@offset_expected:		equr	d2
	@test_cnt:				equr	d7

	lea		Error_GuessCaller, @test_func
	lea		@TestData, @test_data
	moveq	#(@TestData_End-@TestData)/24-1, @test_cnt

	@RunTest:
		move.l	(@test_data)+, @stack_top
		lea		-$10(@stack_top), @stack_bottom
		movem.l	(@test_data)+, @stack_input
		movem.l	@stack_input, (@stack_bottom)

		jsr		(@test_func)

		move.l	(@test_data)+, @offset_expected
		assert.l	@offset, eq, @offset_expected

		dbf		@test_cnt, @RunTest

	rts

; ---------------------------------------------------------------
@TestData:
	dc.l	0		; stack top
	dc.w	$2700, $0000, $003F, $FFFF, $00FE, $FFFE, $0001, $0000		; contents (16 bytes)
	dc.l	$10000	; expected output

	dc.l	0		; stack top
	dc.w	$2700, $0000, $0000, $0000, $0001, $0002, $0001, $0000		; contents (16 bytes)
	dc.l	$10002	; expected output

	dc.l	0		; stack top
	dc.w	$FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF		; contents (16 bytes)
	dc.l	$0		; expected output

	dc.l	-$300		; stack top
	dc.w	$2700, $0000, $003F, $FFFF, $00FE, $FFFE, $0001, $0000		; contents (16 bytes)
	dc.l	$10000	; expected output

	dc.l	-$300		; stack top
	dc.w	$2700, $0000, $0000, $0000, $0001, $0002, $0001, $0000		; contents (16 bytes)
	dc.l	$10002	; expected output

	dc.l	$FF8002		; stack top
	dc.w	$2700, $0000, $003F, $FFFF, $00FE, $FFFE, $0001, $0000		; contents (16 bytes)
	dc.l	$10000	; expected output

	dc.l	$FF8002		; stack top
	dc.w	$2700, $0000, $0000, $0000, $0001, $0002, $0001, $0000		; contents (16 bytes)
	dc.l	$10002	; expected output
@TestData_End:

; ---------------------------------------------------------------

	include	"ErrorHandler.asm"
