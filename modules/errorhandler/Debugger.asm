
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
