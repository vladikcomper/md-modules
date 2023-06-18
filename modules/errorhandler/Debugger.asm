
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Debugging macros definitions file
; ---------------------------------------------------------------

#include Debugger.Extensions.asm


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
