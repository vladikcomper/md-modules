
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; String formatters : Binary number
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

FormatBin_Handlers:
	jmp 	FormatBin_Word(pc)	 			; $00	Word display handler
; ---------------------------------------------------------------
	jmp 	FormatBin_LongWord(pc) 			; $04	Longword display handler
; ---------------------------------------------------------------
;	jmp		FormatBin_Byte(pc)				; $08	Byte display handler

FormatBin_Byte:
	moveq	#8-1, d2

	@loop:
		moveq	#'0'/2,d0
		add.b	d1,d1
		addx.b	d0,d0
		move.b	d0, (a0)+

		dbf		d7, @buffer_ok
		jsr		(a4)
		bcs.s	@quit
	@buffer_ok:

		dbf		d2, @loop

@quit:
	rts

; ---------------------------------------------------------------
FormatBin_LongWord:
	swap	d1
	bsr.s	FormatBin_Word
	bcs.s	FormatBin_Return
	swap	d1

FormatBin_Word:
	moveq	#16-1, d2

	@loop:
		moveq	#'0'/2,d0
		add.w	d1,d1
		addx.b	d0,d0
		move.b	d0, (a0)+

		dbf		d7, @buffer_ok
		jsr		(a4)
		bcs.s	FormatBin_Return
	@buffer_ok:

		dbf		d2, @loop
		
FormatBin_Return:
	rts
