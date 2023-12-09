; ===============================================================
; ---------------------------------------------------------------
; MD Shell 2.5
;
; (c) 2023, Vladikcomper
; ---------------------------------------------------------------


#include ../errorhandler/Debugger.Extensions.asm


#include ../errorhandler/Debugger.Constants.asm


; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

#include ../../build/modules/mdshell-core/MDShell.Globals.asm

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


; ---------------------------------------------------------------
; MD-Shell blob
; ---------------------------------------------------------------

MDShell:
#include ../../build/modules/mdshell-core/MDShell.Blob.asm


#include ../errorhandler/ErrorHandler.Exceptions.asm
