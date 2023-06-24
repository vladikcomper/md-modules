
; =============================================================================
; -----------------------------------------------------------------------------
; Address registers debugger
;
; (c) 2023, Vladikcomper
; -----------------------------------------------------------------------------

		include	"..\core\Macros.asm"			; for "__global", "__injectable"
		include	"..\core\Console.defs.asm"		; for "_pal0", "_newl" etc

; -----------------------------------------------------------------------------
Debugger_AddressRegisters:	__global
		movem.l	a0-a6, -(sp)						; dump registers

		; Setup screen header (position and "Address Registers:" text)
		lea		Str_ScreenHeader(pc), a0
@_inj0:	jsr		Console_Write(pc)

		; Render registers table
		lea		(sp), a4							; get registers dump in the stack ...
		moveq	#7-1, d6							; number of registers to process (minus one)

		move.w	#' '<<8, -(sp)						; STACK => dc.b	_pal0, 'a0: ', 0
		move.l	#(_pal0<<24)|'a0:', -(sp)			; ''

	@loop:
			lea		(sp), a0							; a0 = label
			move.l	(a4)+, d1							; d1 = address register value
@_inj1:		jsr		Error_DrawOffsetLocation(pc)

			addq.b	#1, 2(sp)							; add 1 to register's digit ASCII
			dbf		d6, @loop

		lea		6+4*7(sp), sp						; STACK => free string buffer and registers themselves
		rts

; -----------------------------------------------------------------------------
Str_ScreenHeader:
		dc.b	_newl, _setx, 1, _setw, 38
		dc.b	_pal1, 'Address Registers:', _newl, _newl, 0
		even

	if def(_LINKABLE_)
__blob_end:
	endc

; =============================================================================
; -----------------------------------------------------------------------------
; Injectable routines for a stand-alone build
; -----------------------------------------------------------------------------
; NOTE:
;	Each invocation of them marked with @_injX or __injX symbol will be
;	manually linked by BLOBTOASM utility using the injection map.
; -----------------------------------------------------------------------------

Console_Write:	__injectable
Error_DrawOffsetLocation:	__injectable
