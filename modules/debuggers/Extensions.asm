
; =============================================================================
; -----------------------------------------------------------------------------
; Error handling module
;
; This file builds "external" (opt-in) functions to be included with
; Error handler bundles.
; -----------------------------------------------------------------------------
; (c) 2023, Vladikcomper
; -----------------------------------------------------------------------------

		include	"..\core\Macros.asm"		; for "VDP_Ctrl"
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
@_inj0:	jsr		ErrorHandler_SetupVDP(pc)
@_inj1:	jsr		Error_InitConsole(pc)
		movem.l	(sp)+, d0-a6
@_inj2:	pea		Error_IdleLoop(pc)
		move.l	Console_RAM.size+4(sp), -(sp)	; retrieve return address
		rts										; jump to return address


; =============================================================================
; -----------------------------------------------------------------------------
; A simple controller that allows switching between Debuggers
; -----------------------------------------------------------------------------

ErrorHandler_PagesController:	__global
		move.w	#0, -(sp)					; allocate joypad memory

	@MainLoop:
			lea		VDP_Ctrl, a5				; a5 = VDP_Ctrl
			lea		-4(a5), a6					; a6 = VDP_Data

			; Read joypads
			jsr		VSync(pc)
			lea		(sp), a0					; a0 = Joypad memory
			lea		$A10003, a1					; a1 = Joypad 1 Port
			jsr		ReadJoypad(pc)

			moveq	#$FFFFFFF0, d0
			and.b	1(sp), d0					; Start/A/B/C pressed?
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
@_inj0:		lea		ErrorHandler_ConsoleConfig_Shared(pc), a1
			lea		(sp), a3					; a3 = Console RAM
			vram	VRAM_DebuggerPage, d5		; d5 = Screen start address
@_inj1:		jsr		Console_InitShared(pc)

			; Display debugger's own console
			move.l	#(($8200+VRAM_DebuggerPage/$400)<<16)|($8400+VRAM_DebuggerPage/$2000), (a5)

			; Execute the debugger
			pea		@DestroyDebugger(pc)
			jmp		(a0)						; avoid JSR here so backtrace won't detect it

	; -----------------------------------------------------------------------------
	@DestroyDebugger:
			lea		Console_RAM.size(sp), sp	; deallocate console memory
			bra.s	@MainLoop

	; -----------------------------------------------------------------------------
	@ShowMainErrorScreen:
@_inj2:		move.l	ErrorHandler_VDPConfig_Nametables(pc), (a5)
			bra.s	@MainLoop


; =============================================================================
; -----------------------------------------------------------------------------
; Performs VSync
; -----------------------------------------------------------------------------

VSync:
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

	if def(_LINKABLE_)
__blob_end:
	endc

; -----------------------------------------------------------------------------
; This list must be manually inserted *AFTER* the BLOB
; -----------------------------------------------------------------------------

ErrorHandler_ExtraDebuggerList:	__injectable


; =============================================================================
; -----------------------------------------------------------------------------
; Injectable routines for a stand-alone build
; -----------------------------------------------------------------------------
; NOTE:
;	Each invocation of them marked with @_injX or __injX symbol will be
;	manually linked by BLOBTOASM utility using the injection map.
; -----------------------------------------------------------------------------

ErrorHandler_SetupVDP:	__injectable
Error_InitConsole:	__injectable
Error_IdleLoop:	__injectable
Console_InitShared:	__injectable
ErrorHandler_ConsoleConfig_Shared:	__injectable
ErrorHandler_VDPConfig_Nametables:	__injectable
