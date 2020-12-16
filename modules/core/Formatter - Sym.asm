
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; String formatters : Symbols
; ---------------------------------------------------------------
; INPUT:
;		d1		Value
;
; OUTPUT:
;		(a0)++	ASCII characters upon conversion
;
; WARNING!
;	1) Formatters can only use registers a3 / d0-d4
;	2) Formatters should decrement d7 after each symbol write,
;		return Carry flag from the last decrement;
;		stop if carry is set (means buffer is full)
; ---------------------------------------------------------------

FormatSym_Handlers:
	ext.l	d1							; $00		; handler for word
	bra.s	FormatSym					; $02
; ---------------------------------------------------------------
	jmp		FormatSym(pc)				; $04		; handler for longword
; ---------------------------------------------------------------
	ext.w	d1							; $08		; handler for byte
	ext.l	d1

FormatSym:
	btst	#3, d3							; is "display just label part so far" bit set?
	bne.s	@0								; if yes, branch
	pea		FormatString_CodeHandlers+$40(pc); otherwise, display displacement after this routine is finished
@0:
	movem.l	d1/d3/a1-a2, -(sp)
	jsr		GetSymbolByOffset(pc)			; IN:	d1 = offset
	bne.s	FormatSym_UnknownSymbol			; OUT:	d0/Z = error status, d1 = displacement, a1 = symbol pointer
	move.l	d1, (sp)						; replace offset stored in stack as D1 with displacement
	jsr		DecodeSymbol(pc)				; IN:	a1 = symbol pointer
	movem.l	(sp)+, d1/d3/a1-a2				; NOTICE: This doesn't affect CCR, so this routine still returns Carry

FormatSym_Return:
	rts

; ---------------------------------------------------------------
FormatSym_UnknownSymbol:
	movem.l	(sp)+, d1/d3/a1-a2
  	btst	#2, d3							; is "draw <unknown> on error" bit set?
	beq.s	FormatSym_ReturnNC				; if not, branch
	lea		FormatSym_Str_Unknown(pc), a3
	jmp		FormatString_CodeHandlers+$52(pc)	; jump to code D0 (string) handler, but skip instruction that sets A3

; ---------------------------------------------------------------
FormatSym_ReturnNC:
	moveq	#-1, d0							; reset Carry, keep D0 an error code
	rts

; ---------------------------------------------------------------
FormatSym_Str_Unknown:
	dc.b	'<unknown>',0

; ---------------------------------------------------------------
; INPUT:
;		d1	.l	Displacement
; ---------------------------------------------------------------

FormatSym_Displacement:
	move.b	#'+', (a0)+
	dbf		d7, @buffer_ok
	jsr		(a4)
	bcs.s	FormatSym_Return
@buffer_ok:

	swap	d1								; swap displacement longword
	tst.w	d1								; test higher 16-bits of displacement
	beq		FormatHex_Word_Swapped			; if bits are empty, display displacement as word
	bra		FormatHex_Long_Swapped			; otherwise, display longword

; ---------------------------------------------------------------
; INPUT:
;		d1	.l	Offset
;		d3	.b	Control byte
; ---------------------------------------------------------------

FormatSym_Offset:
	btst	#3, d3							; is "don't draw offset" flag set?
	bne.s	FormatSym_Return				; WARNING: Should return NC
	jmp		FormatHex_LongWord(pc)

