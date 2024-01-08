
; ===============================================================
; ---------------------------------------------------------------
; MD Debugger and Error Handler v.2.6
;
; (c) 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; Debugger definitions
; ---------------------------------------------------------------

#include Debugger.Config.asm


#include Debugger.Constants.asm

#ifdef LINKABLE
#ifdef BUNDLE-ASM68K
#include Debugger.Refs.ASM68K.asm
#else
## AS bundle doesn't support linkable builds!
#endif
#endif


; ===============================================================
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
