
; ===============================================================
; ---------------------------------------------------------------
; Error handling module
;
; This file builds "external" (opt-in) functions to be included
; with Error handler bundles.
;
; You don't have to build it, unless you want to manually modify
; 'bundles\ErrorHandler.Extern.*.asm' files.
; ---------------------------------------------------------------
; (c) 2023, Vladikcomper
; ---------------------------------------------------------------

ErrorHandler.__extern__console_only:
	move	#$2700, sr
	lea		-Console_RAM.size(sp), sp		; allocate memory for console
	movem.l	d0-a6, -(sp)
	lea		$3C(sp), a3						; a3 = Console RAM pointer
	jsr		ErrorHandler_SetupVDP(pc)
	jsr		Error_InitConsole(pc)
	movem.l	(sp)+, d0-a6
	pea		@IdleLoop(pc)
	move.l	Console_RAM.size+4(sp), -(sp)	; retrieve return address
	rts										; jump to return address

@IdleLoop:
	bra.s	@IdleLoop

; ---------------------------------------------------------------

ErrorHandler.__extern__vsync:
	lea		VDP_Ctrl, a0
@0:	move.w	(a0), ccr
	bmi.s	@0
@1:	move.w	(a0), ccr
	bpl.s	@1
	rts

; ---------------------------------------------------------------

	include	"ErrorHandler.asm"
