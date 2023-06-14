#ifndef HEADLESS
; ===============================================================
; ---------------------------------------------------------------
; MD Shell 2.0
;
; (c) 2023, Vladikcomper
; ---------------------------------------------------------------


#include ../errorhandler/Debugger.Constants.asm


; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include ../../build/modules/mdshell/MDShell.Global.ASM68K.asm
#endif
##
##
#ifdef BUNDLE-AS
#include ../../build/modules/mdshell/MDShell.Global.AS.asm
#endif
##

; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include ../errorhandler/Debugger.Macros.ASM68K.asm
#endif
##
##
#ifdef BUNDLE-AS
#include ../errorhandler/Debugger.Macros.AS.asm
#endif
##
#endif


; ---------------------------------------------------------------
; MD-Shell blob
; ---------------------------------------------------------------

MDShell:
#include ../../build/modules/mdshell/MDShell.Blob.asm
