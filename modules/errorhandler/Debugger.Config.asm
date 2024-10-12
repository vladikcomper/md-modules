; ---------------------------------------------------------------
; Debugger customization
; ---------------------------------------------------------------
#ifdef MD-SHELL
#ifndef LINKABLE

; VBlank interrupt handler (default is "IdleInt", which returns immediately)
MDSHELL__VBLANK_HANDLER:				equ		MDDBG__IdleInt

; HBlank interrupt handler (default is "IdleInt", which returns immediately)
MDSHELL__HBLANK_HANDLER:				equ		MDDBG__IdleInt
#endif
#endif

; Enable debugger extensions
; Pressing A/B/C on the exception screen can open other debuggers
; Pressing Start or unmapped button returns to the exception
DEBUGGER__EXTENSIONS__ENABLE:			equ		1		; 0 = OFF, 1 = ON (default)

#ifndef LINKABLE
; Whether to show SR and USP registers in exception handler
DEBUGGER__SHOW_SR_USP:					equ		0		; 0 = OFF (default), 1 = ON

; Debuggers mapped to pressing A/B/C on the exception screen
; Use 0 to disable button, use debugger's entry point otherwise.
DEBUGGER__EXTENSIONS__BTN_A_DEBUGGER:	equ		MDDBG__Debugger_AddressRegisters	; display address register symbols
DEBUGGER__EXTENSIONS__BTN_B_DEBUGGER:	equ		MDDBG__Debugger_Backtrace			; display exception backtrace
DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER:	equ		0		; disabled

; Selects between 24-bit (compact) and 32-bit (full) offset format.
; This affects offset format next to the symbols in the exception screen header.
; M68K bus is limited to 24 bits anyways, so not displaying unused bits saves screen space.
; Possible values:
; - MDDBG__Str_OffsetLocation_24bit (example: 001C04 SomeLoc+4)
; - MDDBG__Str_OffsetLocation_32bit (example: 00001C04 SomeLoc+4)
DEBUGGER__STR_OFFSET_SELECTOR:			equ		MDDBG__Str_OffsetLocation_24bit

#endif