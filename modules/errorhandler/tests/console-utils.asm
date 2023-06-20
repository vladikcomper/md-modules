#include cbundle_disclaimer

; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Console run and console clear tests
; ---------------------------------------------------------------

	include	"..\..\..\build\modules\mdshell\headless\MDShell.asm"

#ifdef ASM68K
	include	"..\..\..\build\modules\errorhandler\asm68k-debug\Debugger.asm"
#else
	include	"..\..\..\build\modules\errorhandler\as\Debugger.asm"
#endif

; --------------------------------------------------------------

Main:
	; Initialize registers with pseudo-random values,
	; found at "RegisterData" byte-array (see below)
	movem.l	RegisterData, d0-a6

	Console.Run TestProgram

; --------------------------------------------------------------
TestProgram:
	Console.SetXY #1, #1
	Console.Write "%<pal1>Refreshing in ~1 second..."
	Console.Sleep #60
	Console.Clear

	Console.WriteLine "Refreshed!"
	Console.Sleep #0
	Console.WriteLine "Printed a line without a delay!"

	jmp		CheckRegisterIntergity


; ==============================================================
; --------------------------------------------------------------
; Subroutine that check if current register values match
; array they were initialized with ...
; --------------------------------------------------------------

CheckRegisterIntergity:
	movem.l	d0-a6, -(sp)

	lea		(sp), a0				; a0 = registers dump pointer
	lea		RegisterData, a1		; a1 = source registers pointer
	moveq	#15-1, d0				; d0 = number of registers minus 1

__loop:
	cmpm.l	(a0)+, (a1)+
	dbne	d0, __loop
	bne.s	__corrupted
	movem.l	(sp)+, d0-a6
	rts

; --------------------------------------------------------------
__corrupted:
	subq.w	#4, a0
	subq.w	#4, a1
	lea		RegisterNames-RegisterData(a1), a2
	lea		$3C(sp), a3

#ifdef ASM68K
	Console.Write "%<endl,pal1>@%<.l (a3) sym|split>: %<endl,pal0> Register %<pal1>%<.l a2 hex>%<pal0> corrupted!%<endl> Got %<pal2>%<.l (a0)>%<pal0>, expected %<pal2>%<.l (a1)>%<pal0,endl>"
#else
##	; AS assembler implementation has limitations on formatting capabilities
##	; Moreover, AS is incapable of parsing stings that include more than 160 characters
	Console.Write "%<endl>%<pal1>@%<.l (a3) sym|split>: %<endl>%<pal0> Register %<pal1>%<.l a2 hex>%<pal0> corrupted!"
	Console.Write "%<endl> Got %<pal2>%<.l (a0)>%<pal0>, expected %<pal2>%<.l (a1)>%<pal0>%<endl>"
#endif
	bra	*

; --------------------------------------------------------------
RegisterData:
	dc.b $47, $2F, $74, $1E, $5B, $57, $06, $22, $38, $3D, $52, $9E, $AF, $4F
	dc.b $BD, $96, $F0, $8A, $3B, $BB, $B9, $E2, $96, $B0, $6E, $26, $FB, $C1
	dc.b $6D, $21, $D0, $06, $41, $04, $0E, $FD, $93, $72, $92, $32, $E0, $AB
	dc.b $2F, $77, $70, $A8, $76, $B6, $0F, $3C, $6D, $7C, $70, $72, $B5, $AA
	dc.b $5A, $CB, $DC, $F9

RegisterNames:
	dc.w 'd0',0,'d1',0,'d2',0,'d3',0,'d4',0,'d5',0,'d6',0,'d7',0
	dc.w 'a0',0,'a1',0,'a2',0,'a3',0,'a4',0,'a5',0,'a6',0

; --------------------------------------------------------------

#ifdef ASM68K
	include	"..\..\..\build\modules\errorhandler\asm68k-debug\ErrorHandler.asm"
#else
	include	"..\..\..\build\modules\errorhandler\as\ErrorHandler.asm"
#endif

