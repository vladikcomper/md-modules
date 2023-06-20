; ---------------------------------------------------------------
; Built-in debuggers
; ---------------------------------------------------------------

Debugger_AddressRegisters:
#include ../../build/modules/debuggers/AddressRegisters.Blob.asm

Debugger_Backtrace:
#include ../../build/modules/debuggers/Backtrace.Blob.asm

; ---------------------------------------------------------------
; Debugger extensions
; ---------------------------------------------------------------

DebuggerExtensions:
#include ../../build/modules/debuggers/Extensions.Blob.asm

; WARNING! Don't move! This must be placed directly below "DebuggerExtensions"
DebuggerExtensions_ExtraDebuggerList:
	dc.l	DEBUGGER__EXTENSIONS__BTN_A_DEBUGGER	; for button A
	dc.l	DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER	; for button C (not B)
	dc.l	DEBUGGER__EXTENSIONS__BTN_B_DEBUGGER	; for button B (not C)
