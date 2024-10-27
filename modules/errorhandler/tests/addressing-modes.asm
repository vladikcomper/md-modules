
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; Test M68K addressing modes covered by macros
; ---------------------------------------------------------------

__DEBUG__:		equ	1		; enable KDebug

	include	"..\..\..\build\modules\mdshell\headless\MDShell.asm"

	if __ASM68K__
		opt		l+			; use "." for local labels for AS compatibility

		include	"..\..\..\build\modules\errorhandler\asm68k-debug\Debugger.asm"
	else
		include	"..\..\..\build\modules\errorhandler\as\Debugger.asm"
	endif

; --------------------------------------------------------------
Main:
	Console.SetXY #1, #1
	Console.WriteLine "%<pal1>TESTS PASS IF VALUES IN BRACKETS MATCH%<pal0>%<endl>"

	moveq	#2, d0
	lea		(DecValues).w, a0

	Console.WriteLine "D0: $%<.w d0> ($0002)"
	Console.WriteLine "A0: %<.w a0 sym> (DecValues)"
	Console.WriteLine "(A0): %<.w (a0) dec> (1234)"
	Console.WriteLine "2(a0): %<.w 2(a0) dec> (5678)"
	Console.WriteLine "X(pc): %<.w DecValues(pc) dec> (1234)"
	Console.WriteLine "X: %<.w DecValues dec> (1234)"
	Console.WriteLine "X.w: %<.w DecValues.w dec> (1234)"
	Console.WriteLine "X.l: %<.w DecValues.w dec> (1234)"
	Console.WriteLine "(X).w: %<.w (DecValues).w dec> (1234)"
	Console.WriteLine "(X).l: %<.w (DecValues).l dec> (1234)"
	Console.WriteLine "#X: %<.w #42 dec> (42)"

	; The following modes are supported only by ASM68K bundles
	if __ASM68K__
		var0:	equr	d0
		Console.WriteLine "D0 (alias): $%<.w var0> ($0002)"
		Console.WriteLine "(A0)+: %<.w (a0)+ dec> (1234)"
		Console.WriteLine "-(A0): %<.w -(a0) dec> (1234)"
		Console.WriteLine "0(a0,d0): %<.w 0(a0,var0) dec> (5678)"
		Console.WriteLine "X(pc,d0): %<.w DecValues(pc,var0) dec> (5678)"
	endif
	rts

DecValues:
	dc.w	1234
	dc.w	5678

; --------------------------------------------------------------

	if __ASM68K__=1
		include	"..\..\..\build\modules\errorhandler\asm68k-debug\ErrorHandler.asm"
	else
		include	"..\..\..\build\modules\errorhandler\as\ErrorHandler.asm"
	endif
