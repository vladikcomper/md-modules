
; ===============================================================
; ---------------------------------------------------------------
; MD Shell
;
; (c) 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; Linkable bundle testing module
; ---------------------------------------------------------------

	section rom

	xdef	SymbolData_Ptr
	xdef	Main

; --------------------------------------------------------------

	include	"..\..\..\build\modules\mdshell\asm68k-linkable\MDShell.asm"

; --------------------------------------------------------------

SymbolData_Ptr:	equ	$200

; --------------------------------------------------------------

Main:
	KDebug.WriteLine "Entering Main..."

	moveq	#$5F, d7
	RaiseError	'Oh look! d7 = %<.w d7>', MyErrorHandler

; --------------------------------------------------------------
MyErrorHandler:
	Console.WriteLine 'Hello, this is a dummy debugger~'
	
	Console.WriteLine '%<pal0>d7 is %<pal2>%<.w d7>%<pal0> in hex'
	Console.WriteLine '- which is %<pal2>%<.w d7 dec>%<pal0> in dec'
	Console.WriteLine '- which is %<pal2>%<.w d7 bin>%<pal0> in binary'

	Console.WriteLine '%<endl>Press any key to continue...'
	Console.Pause

	Console.WriteLine 'Thank you for pressing!'
	rts
