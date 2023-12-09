
; =============================================================================
; -----------------------------------------------------------------------------
; MD Debugger and Error Handler
;
; (c) 2016-2023, Vladikcomper
; -----------------------------------------------------------------------------

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

	if def(_USE_SYMBOL_DATA_REF_)=0
; -----------------------------------------------------------------------------
; Symbol table at the end of the ROM
; -----------------------------------------------------------------------------

SymbolData:
	endc
