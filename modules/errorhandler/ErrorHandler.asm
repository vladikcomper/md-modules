
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Error handler functions and calls
; ---------------------------------------------------------------

#include ErrorHandler.Exceptions.asm


#ifdef BUNDLE-ASM68K
; ---------------------------------------------------------------
; Import error handler global functions
; ---------------------------------------------------------------

#ifdef DEBUG
#include ../../build/modules/errorhandler-core/ErrorHandler.Debug.Globals.asm
#else
#ifdef EXTSYM
#include ../../build/modules/errorhandler-core/ErrorHandler.ExtSymbols.Globals.asm
#else
#include ../../build/modules/errorhandler-core/ErrorHandler.Globals.asm
#endif
#endif
#endif
##
#ifdef BUNDLE-AS
## WARNING! Global functions definitions are moved to Debugger.asm file, since AS sucks at forward-references.
#endif
##

; ---------------------------------------------------------------
; Additional parameters
; ---------------------------------------------------------------

	if DEBUGGER__USE_COMPACT_OFFSETS
		DEBUGGER__STR_OFFSET_SELECTOR:	equ	__global__Str_OffsetLocation_24bit
	else
		DEBUGGER__STR_OFFSET_SELECTOR:	equ	__global__Str_OffsetLocation_32bit
#ifdef BUNDLE-ASM68K
	endc
#else
	endif
#endif

; ---------------------------------------------------------------
; Error handler blob
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

#ifndef EXTSYM
; ---------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; ---------------------------------------------------------------
#endif
