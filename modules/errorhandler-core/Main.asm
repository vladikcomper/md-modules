
; =============================================================================
; -----------------------------------------------------------------------------
; MD Debugger and Error Handler
;
; (c) 2016-2024, Vladikcomper
; -----------------------------------------------------------------------------

; Use smaller text buffers in `Console` and `KDebug` modules, because those are
; stack-allocated and we can be short on stack space during exceptions.
__CONSOLE_TEXT_BUFFER_SIZE__:	equ	$10
__KDEBUG_TEXT_BUFFER_SIZE__:	equ	$10

; -----------------------------------------------------------------------------
; Main Error Handler module
; -----------------------------------------------------------------------------

	; NOTICE: Here and below "..\errorhandler-core" is used as a workaround
	; to also make this code compile from "md-shell" directory.
	include	'..\errorhandler-core\ErrorHandler.asm'

; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------

	include	'..\errorhandler-core\Font.asm'

; -----------------------------------------------------------------------------
; Core modules
; -----------------------------------------------------------------------------

	include	'..\core\Symbols.asm'
	include	'..\core\Formatter_Hex.asm'
	include	'..\core\Formatter_Bin.asm'
	include	'..\core\Formatter_Dec.asm'
	include	'..\core\Formatter_Sym.asm'
	include	'..\core\Format_String.asm'
	include	'..\core\Console.asm'
	include	'..\core\1bpp_Decompress.asm'

; -----------------------------------------------------------------------------
; Extensions
; -----------------------------------------------------------------------------

	include	'..\core\KDebug.asm'
	include	'..\errorhandler-core\Extensions.asm'
	include	'..\errorhandler-core\Debugger_AddressRegisters.asm'
	include	'..\errorhandler-core\Debugger_Backtrace.asm'

	if def(__LINKABLE__)|def(__HEADLESS__)
; -----------------------------------------------------------------------------
; Linkable builds include pre-defined exception vectors
; -----------------------------------------------------------------------------

	include	'..\errorhandler-core\Exceptions.asm'
	endif

	if def(__EXTSYM__)=0
; -----------------------------------------------------------------------------
; Symbol table at the end of the ROM
; -----------------------------------------------------------------------------

SymbolData:
	endif
