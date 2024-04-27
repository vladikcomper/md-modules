
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; ASM68K "dot for local labels" macro compatibility test
; ---------------------------------------------------------------

	section rom
	opt	l+				; use "." for local labels

	xdef	SymbolData_Ptr

	include	"..\..\..\build\modules\mdshell\headless\MDShell.asm"

	include	"..\..\..\build\modules\errorhandler\asm68k-linkable\Debugger.asm"

; --------------------------------------------------------------

SymbolData_Ptr:	equ	$200

; --------------------------------------------------------------

Main:
	nop

.localRef1:
	KDebug.WriteLine "Hello, world! (KDebug device)"
	RaiseError "Dummy exception to test a local symbol for debugger", .localDebugger

; --------------------------------------------------------------
.localDebugger:
	Console.WriteLine "Hello, world! (Console device)"

	Console.WriteLine "Local label test: %<.l #.localRef1 sym>"
	bra.s	.localJump

	KDebug.WriteLine "YOU SHOULD NEVER SEE THIS (SPACE FILLER)"

.localJump:
	KDebug.WriteLine "Local reference test: %<.w .localRef2 dec> (must be 1234)"
	assert.w .localRef2, eq, #1234
	bra.s	GlobalLabel

.localRef2:
	dc.w	1234

GlobalLabel:
	Console.WriteLine "ALL DONE"

.localRef1:
	rts
