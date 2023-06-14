
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Debugging macros definitions file
; ---------------------------------------------------------------


#include Debugger.Constants.asm


#ifdef BUNDLE-AS
; ---------------------------------------------------------------
; Import error handler global functions
; ---------------------------------------------------------------

#ifdef EXTSYM
#include ../../build/modules/errorhandler/ErrorHandler.ExtSymbols.Global.AS.asm
#else
#include ../../build/modules/errorhandler/ErrorHandler.Global.AS.asm
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
