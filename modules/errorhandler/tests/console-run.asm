
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
	Console.Run TestProgram

; --------------------------------------------------------------
TestProgram:
	Console.SetXY #3, #2

	moveq	#8, d0

   	@loop:	Console.Write "%<pal0>%<setx,1>Iteration %<pal2>#%<.w d0>%<endl>"
			dbf		d0, @loop

	Console.Write "%<pal0>Label fetch: %<endl>%<pal1>%<.l #GlobalData+$10 sym>"
	moveq	#2, d0
	Console.SetXY #1, <@YPositionRef(pc,d0)>
	Console.WriteLine "SetXY test!"
	rts

@YPositionRef:
	dc.w	0, 25

; --------------------------------------------------------------
GlobalData:
	dc.w	@record2

	@record0:
		dc.w	0
	@record1:
		dc.w	1
	@record2:
		dc.w	2

		dc.b	'abcdefghi',0
		dc.b	'testing out ...',0
		even


; --------------------------------------------------------------

	include	"..\..\..\build\modules\errorhandler\asm68k-debug\ErrorHandler.asm"
