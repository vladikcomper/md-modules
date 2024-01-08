
; =============================================================================
; -----------------------------------------------------------------------------
; MD Debugger and Error Handler
;
; (c) 2016-2024, Vladikcomper
; -----------------------------------------------------------------------------
; Error Handler Extensions and utilities
; -----------------------------------------------------------------------------


	include	"..\core\Macros.asm"		; for "__global", "VDP_Ctrl"
	include	"..\core\Console.defs.asm"	; for "Console_RAM"


; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------

VRAM_ErrorScreen:	equ		$8000
VRAM_DebuggerPage:	equ		$C000


; =============================================================================
; -----------------------------------------------------------------------------
; Enters a console program specified after the subroutine call
; -----------------------------------------------------------------------------

ErrorHandler_ConsoleOnly:	__global
	move	#$2700, sr
	lea		-Console_RAM.size(sp), sp		; allocate memory for console
	movem.l	d0-a6, -(sp)
	lea		$3C(sp), a3						; a3 = Console RAM pointer
	jsr		ErrorHandler_SetupVDP(pc)
	jsr		Error_InitConsole(pc)
	movem.l	(sp)+, d0-a6
	pea		Error_IdleLoop(pc)
	move.l	Console_RAM.size+4(sp), -(sp)	; retrieve return address
	rts										; jump to return address


; =============================================================================
; -----------------------------------------------------------------------------
; Clears currently used console
; -----------------------------------------------------------------------------

ErrorHandler_ClearConsole:	__global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	movem.l	d0-d1/d5/a1/a5-a6, -(sp)
	lea		VDP_Ctrl, a5				; a5 = VDP_Ctrl
	lea		-4(a5), a6					; a6 = VDP_Data
	lea		ErrorHandler_ConsoleConfig_Initial(pc), a1
	jsr		Console_Reset(pc)
	movem.l	(sp)+, d0-d1/d5/a1/a5-a6
@quit:
	move.l	(sp)+, a3
	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Pause console program executions until A/B/C are pressed
; -----------------------------------------------------------------------------

ErrorHandler_PauseConsole:	__global
	movem.l	d0-d1/a0-a1/a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.w	#0, -(sp)					; allocate joypad memory
	bsr.s	Joypad_Wait_ABCStart		; extra call to initialize joypad bitfield and avoid misdetecting pressed buttons
@loop:
	bsr.s	Joypad_Wait_ABCStart		; is A/B/C pressed?
	beq.s	@loop						; if not, branch

	addq.w	#2, sp

@quit:
	movem.l	(sp)+, d0-d1/a0-a1/a3
	rts


; -----------------------------------------------------------------------------
; Pause console program executions until A/B/C or Start are pressed
; -----------------------------------------------------------------------------
; INPUT:
;		4(sp)	Pointer to a word that stores pressed/held buttons
;
; OUTPUT:
;		d0	.b	Pressed A/B/C/Start state; Format: %SACB0000
;
; USES:
;		d0-d1 / a0-a1
; -----------------------------------------------------------------------------

Joypad_Wait_ABCStart:
	bsr.s	VSync
	lea		4(sp), a0					; a0 = Joypad memory
	lea		$A10003, a1					; a1 = Joypad 1 Port
	bsr.s	ReadJoypad
	moveq	#$FFFFFFF0, d0
	and.b	5(sp), d0					; Start/A/B/C pressed?
	rts									; return Z=0 if pressed


; =============================================================================
; -----------------------------------------------------------------------------
; A simple controller that allows switching between Debuggers
; -----------------------------------------------------------------------------

ErrorHandler_PagesController:	__global
	movem.l	d0-a6, -(sp)				; back up all the registers ...
	move.w	#0, -(sp)					; allocate joypad memory
	bsr.s	Joypad_Wait_ABCStart		; extra call to initialize joypad bitfield and avoid misdetecting pressed buttons

@MainLoop:
		lea		VDP_Ctrl, a5				; a5 = VDP_Ctrl
		lea		-4(a5), a6					; a6 = VDP_Data

		bsr.s	Joypad_Wait_ABCStart		; Start/A/B/C pressed?
		beq.s	@MainLoop					; if not, branch
		bmi.s	@ShowMainErrorScreen		; if Start pressed, branch

		; Detect debugger to run depending on currently pressed button (A/B/C)
		lea		ErrorHandler_ExtraDebuggerList-4-4(pc), a0		; another "-4" to skip always-reset Start button

	@ChkButton:
			addq.l	#4, a0						; next debugger
			add.b	d0, d0
			bcc.s	@ChkButton

		move.l	(a0), d0					; d0 = debugger address
		ble.s	@ShowMainErrorScreen		; if address is zero or negative, branch
		movea.l	d0, a0

		; Initialize console for the debugger
		lea		-Console_RAM.size(sp), sp	; allocate memory for console
		lea		ErrorHandler_ConsoleConfig_Shared(pc), a1
		lea		(sp), a3					; a3 = Console RAM
		vram	VRAM_DebuggerPage, d5		; d5 = Screen start address
		jsr		Console_InitShared(pc)

		; Display debugger's own console
		move.l	#(($8200+VRAM_DebuggerPage/$400)<<16)|($8400+VRAM_DebuggerPage/$2000), (a5)
		move.l	d5, (a5)					; restore last VDP write address

		; Execute the debugger
		pea		@DestroyDebugger(pc)
		pea		(a0)						; use debbuger's context upon return
		movem.l	Console_RAM.size+2+4(sp), d0-a6	; switch to original registers ...
		rts									; switch to debugger's context ...

; -----------------------------------------------------------------------------
@DestroyDebugger:
		lea		Console_RAM.size(sp), sp	; deallocate console memory
		bra.s	@MainLoop

; -----------------------------------------------------------------------------
@ShowMainErrorScreen:
		; WARNING! Make sure a5 is "VDP_Ctrl"!
		move.l	ErrorHandler_VDPConfig_Nametables(pc), (a5)
		bra.s	@MainLoop


; =============================================================================
; -----------------------------------------------------------------------------
; Performs VSync
; -----------------------------------------------------------------------------

VSync:	__global
	lea		VDP_Ctrl, a0

@loop0:
		move.w	(a0), ccr
		bmi.s	@loop0

@loop1:
		move.w	(a0), ccr
		bpl.s	@loop1

	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Reads input from joypad
; -----------------------------------------------------------------------------

ReadJoypad:
	move.b	#0, (a1)			; command to poll for A/Start
	nop							; wait for port (0/1)
	moveq	#$FFFFFFC0, d1		; wait for port (1/1) ... and do useful work (0/1)
	move.b	(a1), d0			; get data for A/Start
	lsl.b	#2, d0
	move.b	#$40, (a1)			; command to poll for B/C/UDLR
	nop							; wait for port (0/1)
	and.b	d1, d0				; wait for port (1/1) ... and do useful work (1/1)
	move.b	(a1), d1			; get data for B/C/UDLR
	andi.b	#$3F, d1
	or.b	d1, d0				; d0 = held buttons bitfield (negated)
	not.b	d0					; d0 = held buttons bitfield (normal)
	move.b	(a0), d1			; d1 = previously held buttons
	eor.b	d0, d1				; toggle off buttons that are being pressed
	move.b	d0, (a0)+			; put raw controller input (for held buttons)
	and.b	d0, d1
	move.b	d1, (a0)+			; put pressed controller input
	rts

; -----------------------------------------------------------------------------
; Extra debugger to button mappings
; -----------------------------------------------------------------------------

ErrorHandler_ExtraDebuggerList:	__global
	dc.l	Debugger_AddressRegisters	; for button A
	dc.l	0							; for button C (not B)
	dc.l	Debugger_Backtrace			; for button B (not C)
