
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
; Pause console program executions until A/B/C are pressed
; -----------------------------------------------------------------------------

ErrorHandler_PauseConsole:	__global
	movem.l	d0-d1/a0-a1/a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.w	#0, -(sp)					; allocate joypad memory
	bsr.s	ReadJoypad_And_CheckABCStart		; extra call to initialize joypad bitfield and avoid misdetecting pressed buttons
@loop:
	bsr.s	ReadJoypad_And_CheckABCStart		; is A/B/C pressed?
	beq.s	@loop						; if not, branch

	addq.w	#2, sp

@quit:
	movem.l	(sp)+, d0-d1/a0-a1/a3
	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Initialize joypads
; -----------------------------------------------------------------------------

InitJoypad:
	moveq	#$40,d0
	move.b	d0, ($A10009).l	; init port 1 (joypad 1)
	move.b	d0, ($A1000B).l	; init port 2 (joypad 2)
	move.b	d0, ($A1000D).l	; init port 3 (extra)
	rts

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

ReadJoypad_And_CheckABCStart:
	bsr		VSync
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
	bsr.s	InitJoypad					; initialize joypads (in case they weren't initilialized before)

	lea		-Console_RAM.size(sp), sp	; allocate memory for console
	move.l	usp, a0
	move.l	a0, -(sp)					; save original debugger's console state
	move.w	#0, -(sp)					; allocate joypad memory

	bsr.s	ReadJoypad_And_CheckABCStart; extra call to initialize joypad bitfield and avoid misdetecting pressed buttons

@MainLoop:
		lea		VDP_Ctrl, a5				; a5 = VDP_Ctrl
		lea		-4(a5), a6					; a6 = VDP_Data

		bsr.s	ReadJoypad_And_CheckABCStart; Start/A/B/C pressed?
		beq.s	@HandleConsoleScrolling		; if not, branch
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
		lea		@ConsoleConfig_SecondaryDebugger(pc), a1
		lea		2+4+Console_RAM.size(sp), a3	; a3 = Console RAM
		jsr		Console_InitShared(pc)

		; Display debugger's own console
		move.l	#(($8200+VRAM_DebuggerPage/$400)<<16)|($8400+VRAM_DebuggerPage/$2000), (a5)
		move.l	d5, (a5)					; restore last VDP write address

		; Execute the debugger
		pea		@MainLoop(pc)
		pea		(a0)								; use debbuger's context upon return
		movem.l	2+4+Console_RAM.size+4(sp), d0-a6	; switch to original registers ...
		rts											; switch to debugger's context ...

	; -----------------------------------------------------------------------------
	@HandleConsoleScrolling:
			move.b	1(sp), d0						; d0 = pressed buttons, extacted by `ReadJoypad_And_CheckABCStart`
			bsr.s	HandleConsoleScrolling
			bra		@MainLoop

	; -----------------------------------------------------------------------------
	@ShowMainErrorScreen:
			move.l	ErrorHandler_VDPConfig_Nametables(pc), (a5)
			move.l	2(sp), a0
			move.l	a0, usp									; restore console state
			moveq	#0, d0
			moveq	#0, d1
			bsr		Console_SetXYTileScrollPosition			; reset console scrolling
			bra		@MainLoop

; -----------------------------------------------------------------------------
@ConsoleConfig_SecondaryDebugger:
	dcvram	VRAM_DebuggerPage			; screen start address / plane nametable pointer
	dcvram	VRAM_ErrorHScroll			; HSRAM address
	dc.w	VSRAM_ErrorVScroll			; VSRAM address

	dc.w	40							; number of characters per line
	dc.w	40							; number of characters on the first line (meant to be the same as the above)
	dc.w	0							; base font pattern (tile id for ASCII $00 + palette flags)
	dc.w	$80							; size of screen row (in bytes)

	dc.w	$2000/$20-1					; size of screen (in tiles - 1)

; -----------------------------------------------------------------------------
;
; -----------------------------------------------------------------------------
; INPUT:
;		d0	.b		Pressed buttons bitfield
;
; USES:
;		d0-d1
; -----------------------------------------------------------------------------

HandleConsoleScrolling:
	lsl.b	#4, d0
	bmi.s	@ScrollRight
	add.b	d0, d0
	bmi.s	@ScrollLeft
	add.b	d0, d0
	bmi.s	@ScrollDown
	add.b	d0, d0
	bpl.s	@Quit

@ScrollUp:
	bsr		Console_GetXYTileScrollPosition
	subq.b	#1, d1
	bra		Console_SetXYTileScrollPosition

@ScrollDown:
	bsr		Console_GetXYTileScrollPosition
	addq.b	#1, d1
	bra		Console_SetXYTileScrollPosition

@ScrollLeft:
	bsr		Console_GetXYTileScrollPosition
	subq.b	#1, d0
	bra		Console_SetXYTileScrollPosition

@ScrollRight:
	bsr		Console_GetXYTileScrollPosition
	addq.b	#1, d0
	bra		Console_SetXYTileScrollPosition

@Quit:
	rts

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


; -----------------------------------------------------------------------------
; Extra debugger to button mappings
; -----------------------------------------------------------------------------

ErrorHandler_ExtraDebuggerList:	__global
	dc.l	Debugger_AddressRegisters	; for button A
	dc.l	0							; for button C (not B)
	dc.l	Debugger_Backtrace			; for button B (not C)
