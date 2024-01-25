; ===============================================================
; ---------------------------------------------------------------
; MD Shell v.2.6
;
; (c) 2023-2024, Vladikcomper
; ---------------------------------------------------------------


#include ../errorhandler/Debugger.Config.asm


#include ../errorhandler/Debugger.Constants.asm

#ifdef LINKABLE
#ifdef BUNDLE-ASM68K
; ===============================================================
; ---------------------------------------------------------------
; Symbols imported from the object file
; ---------------------------------------------------------------

#include ../../build/modules/mdshell-core/MDShell.Refs.asm
#else
## AS bundle doesn't support linkable builds!
#endif
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


#ifndef LINKABLE
; ---------------------------------------------------------------
; MD-Shell blob
; ---------------------------------------------------------------

MDShell:
#include ../../build/modules/mdshell-core/MDShell.Blob.asm


; ---------------------------------------------------------------
; MD-Shell's exported symbols
; ---------------------------------------------------------------

#include ../../build/modules/mdshell-core/MDShell.Globals.asm

#include ../errorhandler/ErrorHandler.Exceptions.asm
#endif
