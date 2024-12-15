
; ===============================================================
; ---------------------------------------------------------------
; MD Debugger and Error Handler v.2.6
;
;
; Documentation, references and source code are available at:
; - https://github.com/vladikcomper/md-modules
;
; (c) 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; Debugger and Error handler blob
; ---------------------------------------------------------------

#include ErrorHandler.Exceptions.asm


; ---------------------------------------------------------------
; MD Debugger blob
; ---------------------------------------------------------------

ErrorHandler:
#ifdef DEBUG
#include ../../build/modules/errorhandler-core/ErrorHandler.Debug.Blob.asm
#else
#ifdef EXTSYM
#include ../../build/modules/errorhandler-core/ErrorHandler.ExtSymbols.Blob.asm
#else
#include ../../build/modules/errorhandler-core/ErrorHandler.Blob.asm
#endif
#endif

; ---------------------------------------------------------------
; MD Debugger's exported symbols
; ---------------------------------------------------------------

#ifdef EXTSYM
#include ../../build/modules/errorhandler-core/ErrorHandler.ExtSymbols.Globals.asm
#else
#ifdef DEBUG
#include ../../build/modules/errorhandler-core/ErrorHandler.Debug.Globals.asm
#else
#include ../../build/modules/errorhandler-core/ErrorHandler.Globals.asm
#endif
#endif

#ifndef EXTSYM
; ---------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; ---------------------------------------------------------------
#endif
