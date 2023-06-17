
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Debugging macros definitions file
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Debugger customization
; ---------------------------------------------------------------

; Enable debugger extensions
; Pressing A/B/C on the exception screen can open other debuggers
; Pressing Start or unmapped button returns to the exception
DEBUGGER__EXTENSIONS__ENABLE:			equ		1		; 0 = OFF, 1 = ON

; Debuggers mapped to pressing A/B/C on the exception screen
; Use 0 to disable button, use debugger's entry point otherwise.
DEBUGGER__EXTENSIONS__BTN_A_DEBUGGER:	equ		0		; disabled
DEBUGGER__EXTENSIONS__BTN_B_DEBUGGER:	equ		Debugger_Backtrace	; display exception backtrace
DEBUGGER__EXTENSIONS__BTN_C_DEBUGGER:	equ		0		; disabled


#include Debugger.Constants.asm


#ifdef BUNDLE-AS
; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

; Debugger extension functions
#include ../../build/modules/debuggers/Extensions.Globals.asm

; Error handler & core functions
#ifdef EXTSYM
#include ../../build/modules/errorhandler-core/ErrorHandler.ExtSymbols.Globals.asm
#else
#include ../../build/modules/errorhandler-core/ErrorHandler.Globals.asm
#endif
#endif

; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include Debugger.Macros.ASM68K.asm
#endif
##
##
#ifdef BUNDLE-AS
#include Debugger.Macros.AS.asm
#endif
##
