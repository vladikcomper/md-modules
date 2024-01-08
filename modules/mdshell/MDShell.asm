; ===============================================================
; ---------------------------------------------------------------
; MD Shell 2.5
;
; (c) 2023, Vladikcomper
; ---------------------------------------------------------------


#include ../errorhandler/Debugger.Config.asm


#include ../errorhandler/Debugger.Constants.asm


#ifdef BUNDLE-ASM68K
; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

#include ../../build/modules/mdshell-core/MDShell.Globals.asm
#endif

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


#ifdef BUNDLE-AS
; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

#include ../../build/modules/mdshell-core/MDShell.Globals.asm
#endif

#include ../errorhandler/ErrorHandler.Exceptions.asm
