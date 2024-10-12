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
Console.ScreenPosReq	rs.l	1				;		current on-screen position request for VDP
Console.ScreenRowReq:	rs.l	1				;		start of row position request for VDP
Console.CharsPerLine	rs.w	1				; d2	number of characters per line
Console.CharsRemaining	rs.w	1				; d3	remaining number of characters
Console.BasePattern		rs.w	1				; d4	base pattern
Console.ScreenRowSz		rs.w	1				; d6	row size within screen position
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

_ConsolePtrMagic:	equ	$5D

; Default size of a text buffer used by `FormatString`, allocated
; on the stack.
; MD Debugger uses a smaller buffer, because the stack is usually
; quite busy by the time exception is thrown.
	if def(__CONSOLE_TEXT_BUFFER_SIZE__)=0
__CONSOLE_TEXT_BUFFER_SIZE__:	equ	$30
	endif

; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

; This macro checks if `ptrAReg` (e.g. `a3`) has contains a valid Console RAM pointer.
; The pointer is valid if its MSB contains the value of "_ConsolePtrMagic".
; This way we usually can test whether we're inside the Console or not.
;
; ARGUMENTS:
;	ptrAReg - any of An registers that stores Console RAM pointer;
;	scratchDReg - a Dn register that will be used for in-place calculations.

Console_ChkRAMPointerValid: macro ptrAReg, scratchDReg
	move.l	\ptrAReg, \scratchDReg
	swap	\scratchDReg
	clr.b	\scratchDReg
	cmp.w	#_ConsolePtrMagic<<8, \scratchDReg	; is MSB of `usp` set to `_ConsolePtrMagic`?
	endm

	endif	; _CONSOLE_DEFS
