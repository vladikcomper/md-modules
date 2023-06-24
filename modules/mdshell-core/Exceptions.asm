
; ===============================================================
; ---------------------------------------------------------------
; MD-Shell 2.5
; Exceptions module
; ---------------------------------------------------------------
; (c) 2023, Vladikcomper
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Errors vector table
; ---------------------------------------------------------------

_eh_default			equ	0
_eh_address_error	equ	$01		; use for address and bus errors only (tells error handler to display additional "Address" field)

__ErrorMessage &
	macro	string, opts
		jsr		ErrorHandler
		dc.b	\string, 0
		dc.b	\opts+0
		even
	endm

; ---------------------------------------------------------------

BusError:
	__ErrorMessage "BUS ERROR", _eh_default|_eh_address_error

AddressError:
	__ErrorMessage "ADDRESS ERROR", _eh_default|_eh_address_error

IllegalInstr:
	__ErrorMessage "ILLEGAL INSTRUCTION", _eh_default

ZeroDivide:
	__ErrorMessage "ZERO DIVIDE", _eh_default

ChkInstr:
	__ErrorMessage "CHK INSTRUCTION", _eh_default

TrapvInstr:
	__ErrorMessage "TRAPV INSTRUCTION", _eh_default

PrivilegeViol:
	__ErrorMessage "PRIVILEGE VIOLATION", _eh_default

Trace:
	__ErrorMessage "TRACE", _eh_default

Line1010Emu:
	__ErrorMessage "LINE 1010 EMULATOR", _eh_default

Line1111Emu:
	__ErrorMessage "LINE 1111 EMULATOR", _eh_default

ErrorExcept:
	__ErrorMessage "ERROR EXCEPTION", _eh_default
