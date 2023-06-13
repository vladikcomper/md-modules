
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; String formatters : Binary number
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
;		Carry=0 if buffer is not terminated, Carry=1 otherwise.
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
