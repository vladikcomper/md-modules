#ifndef HEADLESS
; ===============================================================
; ---------------------------------------------------------------
; MD Shell 2.0
; 2023, Vladikcomper
; ---------------------------------------------------------------


#include ../../errorhandler/bundles/Debugger.Constants.asm


; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include MDShell.Global.ASM68K.asm
#endif
##
##
#ifdef BUNDLE-AS
#include MDShell.Global.AS.asm
#endif
##

; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include ../../errorhandler/bundles/Debugger.Macros.ASM68K.asm
#endif
##
##
#ifdef BUNDLE-AS
#include ../../errorhandler/bundles/Debugger.Macros.AS.asm
#endif
##
#endif


; ---------------------------------------------------------------
; MD-Shell blob
; ---------------------------------------------------------------

MDShell:
#include MDShell.Blob.asm
