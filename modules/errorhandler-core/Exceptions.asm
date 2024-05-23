
; =============================================================================
; -----------------------------------------------------------------------------
; MD Debugger and Error Handler
;
; (c) 2016-2024, Vladikcomper
; -----------------------------------------------------------------------------
; Standard Exception Vectors
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; NOTICE: This code is only included in MD Shell and "asm68k-linkable" bundle
; of MD Debugger. Other bundles allow customization outside of this blob.
; -----------------------------------------------------------------------------


; Screen appearence flags
_eh_address_error	equ	$01		; use for address and bus errors only (tells error handler to display additional "Address" field)
_eh_show_sr_usp		equ	$02		; displays SR and USP registers content on error screen

; Advanced execution flags
; WARNING! For experts only, DO NOT USE them unless you know what you're doing
_eh_return			equ	$20
_eh_enter_console	equ	$40
_eh_align_offset	equ	$80

; Default error handler configuration
_eh_default			equ	0 ;_eh_show_sr_usp

; -----------------------------------------------------------------------------
__ErrorMessage: macro	string, opts
	jsr		ErrorHandler(pc)
	dc.b	\string, 0
	dc.b	\opts+_eh_return|(((*&1)^1)*_eh_align_offset)	; add flag "_eh_align_offset" if the next byte is at odd offset ...
	even													; ... to tell Error handler to skip this byte, so it'll jump to ...
	jmp		ErrorHandler_PagesController(pc)				; ... extensions controller
	endm

; -----------------------------------------------------------------------------

BusError:	__global
	__ErrorMessage "BUS ERROR", _eh_default|_eh_address_error

AddressError:	__global
	__ErrorMessage "ADDRESS ERROR", _eh_default|_eh_address_error

IllegalInstr:	__global
	__ErrorMessage "ILLEGAL INSTRUCTION", _eh_default

ZeroDivide:	__global
	__ErrorMessage "ZERO DIVIDE", _eh_default

ChkInstr:	__global
	__ErrorMessage "CHK INSTRUCTION", _eh_default

TrapvInstr:	__global
	__ErrorMessage "TRAPV INSTRUCTION", _eh_default

PrivilegeViol:	__global
	__ErrorMessage "PRIVILEGE VIOLATION", _eh_default

Trace:	__global
	__ErrorMessage "TRACE", _eh_default

Line1010Emu:	__global
	__ErrorMessage "LINE 1010 EMULATOR", _eh_default

Line1111Emu:	__global
	__ErrorMessage "LINE 1111 EMULATOR", _eh_default

ErrorExcept:	__global
	__ErrorMessage "ERROR EXCEPTION", _eh_default
