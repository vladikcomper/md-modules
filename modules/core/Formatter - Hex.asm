
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; String formatters : Hexidecimal number
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

FormatHex_Handlers:
	jmp		FormatHex_Word(pc)			; $00		; handler for word
; ---------------------------------------------------------------
	jmp		FormatHex_LongWord(pc)		; $04		; handler for longword
; ---------------------------------------------------------------
;	jmp		FormatHex_Byte(pc)			; $08		; handler for byte

FormatHex_Byte:
	moveq	#$F,d3
	move.w	d1,d2
	lsr.w	#4,d2
	and.w	d3,d2
	move.b	HexDigitToChar(pc,d2), (a0)+
	
	dbf		d7, @buffer_ok
	jsr		(a4)
	bcs.s	FormatHex_Return
@buffer_ok

	and.w	d3,d1
	move.b	HexDigitToChar(pc,d1), (a0)+
	dbf		d7, FormatHex_Return
	jmp		(a4)						; call buffer flush function and return buffer status

; ---------------------------------------------------------------
FormatHex_LongWord:
	swap	d1

FormatHex_LongWord_Swapped:
	bsr.s	FormatHex_Word
	bcs.s	FormatHex_Return			; if buffer terminated, branch

FormatHex_Word_Swapped:
	swap	d1

; ---------------------------------------------------------------
FormatHex_Word:
	moveq	#4,d2
	moveq	#$F,d3

	rept 4-1
		rol.w	d2,d1
		move.b	d1,d4
		and.w	d3,d4						; get digit
		move.b	HexDigitToChar(pc,d4), (a0)+
		dbf		d7, *+6
		jsr		(a4)						; call buffer flush function
		bcs.s	FormatHex_Return			; if buffer terminated, branch
	endr

	rol.w	d2,d1
	move.b	d1,d4
	and.w	d3,d4						; get digit
	move.b	HexDigitToChar(pc,d4), (a0)+
	dbf		d7, FormatHex_Return
	jmp		(a4)						; call buffer flush function and return buffer status

FormatHex_Return:
	rts									; return buffer status

; ---------------------------------------------------------------
HexDigitToChar:
	dc.b	'0123456789ABCDEF'
