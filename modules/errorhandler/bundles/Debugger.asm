
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Debugging macros definitions file
; ---------------------------------------------------------------


#include Debugger.Constants.asm


#ifdef BUNDLE-AS
; ---------------------------------------------------------------
; Import error handler global functions
; ---------------------------------------------------------------

#include ErrorHandler.Global.AS.asm
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
