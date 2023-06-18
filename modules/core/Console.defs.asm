	if def(_CONSOLE_DEFS)=0
_CONSOLE_DEFS:	equ	1

; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Console Module (definitions only)
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; RAM structure
; ---------------------------------------------------------------

			rsreset
Console_RAM				equ		__rs
Console.ScreenPosReq	rs.l	1				;		screen position request for VDP
Console.CharsPerLine	rs.w	1				; d2	number of characters per line
Console.CharsRemaining	rs.w	1				; d3	remaining number of characters
Console.BasePattern		rs.w	1				; d4	base pattern
Console.ScreenRowSz		rs.w	1				; d6	row size within screen position
Console.Magic			rs.w	1				;		should contain a magic string to ensure this is valid console memory area
Console_RAM.size		equ		__rs-Console_RAM

; ---------------------------------------------------------------
; Constants
; ---------------------------------------------------------------

; Drawing flags supported in strings
_newl	equ		$E0
_cr		equ		$E6
_pal0	equ		$E8
_pal1	equ		$EA
_pal2	equ		$EC
_pal3	equ		$EE

_setw	equ		$F0
_setoff	equ		$F4
_setpat	equ		$F8
_setx	equ		$FA

_ConsoleMagic	equ	'CO'

	endc	; _CONSOLE_DEFS
