
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Console testing module
; ---------------------------------------------------------------

	include	"..\..\..\build\modules\mdshell\headless\MDShell.asm"

	include	"..\..\..\build\modules\errorhandler\asm68k-debug\Debugger.asm"

; --------------------------------------------------------------

Main:
	moveq	#$5F, d7

	RaiseError	'Oh look! d7 = %<.w d7>', MyErrorHandler

; --------------------------------------------------------------
MyErrorHandler:
	Console.WriteLine 'Hello, this is a dummy debugger~'
	
	Console.WriteLine '%<pal0>d7 is %<pal2>%<.w d7>%<pal0> in hex'
	Console.WriteLine '- which is %<pal2>%<.w d7 dec>%<pal0> in dec'
	Console.WriteLine '- which is %<pal2>%<.w d7 bin>%<pal0> in binary'

	rts

; --------------------------------------------------------------

	include	"..\..\..\build\modules\errorhandler\asm68k-debug\ErrorHandler.asm"
