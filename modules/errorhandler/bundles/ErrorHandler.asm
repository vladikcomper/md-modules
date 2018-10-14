
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Error handler functions and calls
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Error handler control flags
; ---------------------------------------------------------------

; Screen appearence flags
_eh_address_error	equ	$01		; use for address and bus errors only (tells error handler to display additional "Address" field)
_eh_show_sr_usp		equ	$02		; displays SR and USP registers content on error screen

; Advanced execution flags
; WARNING! For experts only, DO NOT USES them unless you know what you're doing
_eh_return			equ	$20
_eh_enter_console	equ	$40
_eh_align_offset	equ	$80

; ---------------------------------------------------------------
; Errors vector table
; ---------------------------------------------------------------

; Default screen configuration
_eh_default			equ	0 ;_eh_show_sr_usp

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



#ifdef BUNDLE-ASM68K
; ---------------------------------------------------------------
; Import error handler global functions
; ---------------------------------------------------------------

#ifdef DEBUG
#include ErrorHandler.Debug.Global.ASM68K.asm
#else
#include ErrorHandler.Global.ASM68K.asm
#endif
#endif
##
#ifdef BUNDLE-AS
## WARNING! Global functions definitions are moved to Debugger.asm file, since AS sucks with forward-references.
#endif
##


; ---------------------------------------------------------------
; Error handler external functions (compiled only when used)
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include ErrorHandler.Extern.ASM68K.asm
#endif
##
#ifdef BUNDLE-AS
#include ErrorHandler.Extern.AS.asm
#endif
##

; ---------------------------------------------------------------
; Include error handler binary module
; ---------------------------------------------------------------

ErrorHandler:
#ifdef BUNDLE-ASM68K
	incbin	ErrorHandler.bin
#endif
##
#ifdef BUNDLE-AS
	binclude "ErrorHandler.bin"
#endif
##

; ---------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; ---------------------------------------------------------------
