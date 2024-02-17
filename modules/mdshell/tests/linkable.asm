
; ===============================================================
; ---------------------------------------------------------------
; MD Shell
;
; (c) 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; Linkable bundle testing module
; ---------------------------------------------------------------

	section rom

	xdef	Main

; --------------------------------------------------------------

	include	"..\..\..\build\modules\mdshell\asm68k-linkable\MDShell.asm"

; --------------------------------------------------------------

Main:
	; In linkable builds, `.Write[Line]` functions store strings
	; in `dbgstrings` section and they switch back and forth
	; between `rom` and `dbgstrings` in macro invocation.
	; In this stress test we ensure
	; both ASM68K and PSYLINK are able to handle many section
	; switches without issues.
	KDebug.WriteLine "Linkable KDebug stress test..."
	@counter: = 0
	rept 1024
		@counter: = @counter + 1
		KDebug.WriteLine "Wrote stored string \#@counter/1024."
	endr

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
