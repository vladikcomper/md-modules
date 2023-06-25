
; =============================================================================
; -----------------------------------------------------------------------------
; Error handling module
;
; This file builds "external" (opt-in) functions to be included with
; Error handler bundles.
; -----------------------------------------------------------------------------
; (c) 2023, Vladikcomper
; -----------------------------------------------------------------------------

		include	"..\core\Macros.asm"		; for "__global", "__injectable", "VDP_Ctrl"
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
@_inj0:	lea		ErrorHandler_ConsoleConfig_Initial(pc), a1
@_inj1:	jsr		Console_Reset(pc)
		movem.l	(sp)+, d0-d1/d5/a1/a5-a6
@quit:
		move.l	(sp)+, a3
		rts


; =============================================================================
; -----------------------------------------------------------------------------
; Write formatted strings to KDebug message buffer
; -----------------------------------------------------------------------------
; INPUT:
;		a1		Pointer to source formatted string
;		a2		Arguments buffer pointer
;
; USES:
;		a0-a2, d7
; -----------------------------------------------------------------------------

KDebug_WriteLine_Formatted: __global
		pea		KDebug_FlushLine(pc)

; -----------------------------------------------------------------------------
KDebug_Write_Formatted: __global

@buffer_size = $10

		move.l	usp, a0
		cmp.b	#_ConsoleMagic, Console.Magic(a0)	; are we running console?
		beq.s	@quit						; if yes, disable KDebug output, because it breaks VDP address

		move.l	a4, -(sp)
		lea		@FlushBuffer(pc), a4		; flushing function
		lea		-@buffer_size(sp), sp		; allocate string buffer
		lea		(sp), a0					; a0 = string buffer
		moveq	#@buffer_size-2, d7			; d7 = number of characters before flush -1

@_inj0:	jsr		FormatString(pc)
		lea		@buffer_size(sp), sp		; free string buffer
		
		move.l	(sp)+, a4
@quit:
		rts

; ---------------------------------------------------------------
; Flush buffer callback raised by FormatString
; ---------------------------------------------------------------
; INPUT:
;		a0		Buffer position
;		d7	.w	Number of characters remaining in buffer - 1
;
; OUTPUT:
;		a0		Buffer position after flushing
;		d7	.w	Number of characters before next flush - 1
;		Carry	0 = continue operation
;				1 = terminate FormatString with error condition
;
; WARNING: This function shouldn't modify d0-d4 / a1-a3!
; ---------------------------------------------------------------

@FlushBuffer:
		clr.b	(a0)+					; finalize buffer

		neg.w	d7
		add.w	#@buffer_size-1, d7
		sub.w	d7, a0					; a0 = start of the buffer

		move.l	a0, -(sp)
		move.l	a5, -(sp)

		lea		VDP_Ctrl, a5
		move.w	#$9E00, d7
		bra.s	@write_buffer_next

		@write_buffer:
			move.w	d7, (a5)

		@write_buffer_next:
			move.b	(a0)+, d7
			bgt.s	@write_buffer			; if not null-terminator or flag, branch
			beq.s	@write_buffer_done		; if null-terminator, branch
			sub.b	#_newl, d7				; is flag "new line"?
			beq.s	@write_buffer			; if yes, branch
			bra.s	@write_buffer_next		; otherwise, skip writing

	; -----------------------------------------------------------------------------
	@write_buffer_done:
		move.l	(sp)+, a5
		move.l	(sp)+, a0
		moveq	#@buffer_size-2, d7		; d7 = number of characters before flush -1
		rts								; WARNING! Must return Carry=0


; =============================================================================
; -----------------------------------------------------------------------------
; Finishes the current line and flushes KDebug message buffer
; -----------------------------------------------------------------------------

KDebug_FlushLine:	__global
		move.l	a0, -(sp)
		move.l	usp, a0
		cmp.b	#_ConsoleMagic, Console.Magic(a0)	; are we running console?
		beq.s	@quit						; if yes, disable KDebug output, because it breaks VDP address

		move.w	#$9E00, VDP_Ctrl			; send null-terminator
@quit:
		move.l	(sp)+, a0
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
@_inj0:		lea		ErrorHandler_ConsoleConfig_Shared(pc), a1
			lea		(sp), a3					; a3 = Console RAM
			vram	VRAM_DebuggerPage, d5		; d5 = Screen start address
@_inj1:		jsr		Console_InitShared(pc)

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
@_inj2:		move.l	ErrorHandler_VDPConfig_Nametables(pc), (a5)
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
Console_Reset: __injectable
Console_InitShared:	__injectable
FormatString:	__injectable
ErrorHandler_ConsoleConfig_Initial:	__injectable
ErrorHandler_ConsoleConfig_Shared:	__injectable
ErrorHandler_VDPConfig_Nametables:	__injectable
