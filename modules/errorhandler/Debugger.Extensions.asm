; ---------------------------------------------------------------
; Debugger customization
; ---------------------------------------------------------------

; Use compact 24-bit offsets instead of 32-bit ones
; This will display shorter offests next to the symbols in the exception screen header.
; M68K bus is limited to 24 bits anyways, so not displaying unused bits saves screen space.
DEBUGGER__USE_COMPACT_OFFSETS:			equ		1		; 0 = OFF, 1 = ON

; Enable debugger extensions
; Pressing A/B/C on the exception screen can open other debuggers
; Pressing Start or unmapped button returns to the exception
DEBUGGER__EXTENSIONS__ENABLE:			equ		1		; 0 = OFF, 1 = ON

; Debuggers mapped to pressing A/B/C on the exception screen
; Use 0 to disable button, use debugger's entry point otherwise.
DEBUGGER__EXTENSIONS__BTN_A_DEBUGGER:	equ		__global__Debugger_AddressRegisters	; display address register symbols
DEBUGGER__EXTENSIONS__BTN_B_DEBUGGER:	equ		__global__Debugger_Backtrace		; display exception backtrace
DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER:	equ		0		; disabled