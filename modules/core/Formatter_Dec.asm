
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; String formatters : Decimal number
; ---------------------------------------------------------------
; INPUT:
;		d1		Value
;
;		d7	.w	Number of bytes left in buffer, minus one
;		a0		String buffer
;		a4		Buffer flush function
;
; OUTPUT:
;		(a0)++	ASCII characters for the converted value
;
; WARNING!
;	1) Formatters can only use registers a3 / d0-d4
;	2) Formatters should decrement d7 after each symbol write.
;	3) When d7 decrements below 0, a buffer flush function
;		loaded in a4 should be called. The standard function
;		usually renders buffer's contents on the screen (see
;		"Console_FlushBuffer"), then resets the buffer.
;		This function will reload d7, a0 and Carry flag.
;	4) If Carry flag is set after calling buffer flush function,
;		formatter should halt all further processing and return,
;		retaining the returned Carry bit.
; ---------------------------------------------------------------

FormatDec_Handlers:
	jmp 	FormatDec_Word(pc)	 			; $00	Word display handler
; ---------------------------------------------------------------
	jmp 	FormatDec_LongWord(pc) 			; $04	Longword display handler
; ---------------------------------------------------------------
	lea 	DecimalBase_Byte(pc), a3			; $08	Byte display handler
	andi.w	#$FF, d1								; ...
	bra.s 	FormatDec			 				; ...

; ---------------------------------------------------------------
FormatDec_Word:
	lea 	DecimalBase_Word(pc), a3

FormatDec:
	clr.b	d0						; d0 will be trim zeros switcher
	moveq	#9, d3					; d3 will be DBcc iterator base
	move.w	(a3)+, d4				; d4 = decimal base

FormatDec_Cont:
	@ProcessDigit:
		move.w	d3, d2

		@FindDigit:
			sub.w	d4, d1
			dbcs	d2, @FindDigit

		add.w	d4, d1							; restore digit
		sub.w	d3, d2
		neg.w	d2								; d2 = digit
		or.b	d2, d0							; have we met non-zero digit yet?
		beq.s	@NextDigit						; if not, branch
		add.b	#'0', d2
		move.b	d2, (a0)+

		dbf		d7, @NextDigit
		jsr		(a4)
		bcs.s	FormatDec_Return

	@NextDigit:
		move.w	(a3)+, d4
		bpl.s	@ProcessDigit

	; The last digit is done manually
	add.b	#'0', d1
	move.b	d1, (a0)+
	dbf		d7, FormatDec_Return
	jmp		(a4)

FormatDec_Return:
	rts

; ---------------------------------------------------------------
FormatDec_LongWord:
	lea 	DecimalBase_Long(pc), a3
	clr.b	d0						; d0 will be trim zeros switcher
	moveq	#9, d3					; d3 will be DBcc iterator base
	move.l	(a3)+, d4				; d4 = decimal base

	@ProcessDigit:
		move.w	d3, d2
		
		@FindDigit:
			sub.l	d4, d1
			dbcs	d2, @FindDigit

		add.l	d4, d1							; restore digit
		sub.w	d3, d2
		neg.w	d2								; d2 = digit
		or.b	d2, d0							; have we met non-zero digit yet?
		beq.s	@NextDigit						; if not, branch
		add.b	#'0', d2
		move.b	d2, (a0)+
		
		dbf		d7, @NextDigit
		jsr		(a4)
		bcs.s	FormatDec_Return

	@NextDigit:
		move.l	(a3)+, d4				; load next decimal base
		bpl.s	@ProcessDigit			; if base is positive, branch
										; otherwise, base is word-sized ...

	bra.s	FormatDec_Cont		; continue drawing with word-sized version
										; note that lower word of D4 already contains next decimal base ...

; ---------------------------------------------------------------
DecimalBase_Long:
	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.w	-1				; marks switching between 'long' and 'word' modes
	dc.w	1000
	dc.w	100
	dc.w	10
	dc.w	-1				; marks end of digit searching

; ---------------------------------------------------------------
DecimalBase_Word:
	dc.w	10000
	dc.w	1000

DecimalBase_Byte:
	dc.w	100
	dc.w	10
	dc.w	-1				; marks end of digit searching
