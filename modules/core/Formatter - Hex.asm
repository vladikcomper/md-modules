
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
	and.w	d3,d2						; get nibble
	move.b	HexDigitToChar(pc,d2), (a0)+
	
	dbf		d7, FormatHex_Word_WriteLastNibble
	jsr		(a4)
	bcc.s	FormatHex_Word_WriteLastNibble
	rts		; return Carry=1

; ---------------------------------------------------------------
FormatHex_LongWord:
	swap	d1

FormatHex_LongWord_Swapped:
	bsr.s	FormatHex_Word
	bcs.s	FormatHex_Return			; if buffer terminated, branch

FormatHex_Word_Swapped:
	swap	d1
	;fallthrough

; ---------------------------------------------------------------
FormatHex_Word:
	moveq	#4,d2
	moveq	#$F,d3

	rept 4-1
		rol.w	d2,d1
		move.b	d1,d4
		and.w	d3,d4						; get nibble
		move.b	HexDigitToChar(pc,d4), (a0)+
		dbf		d7, *+6						; if buffer is not exhausted, branch
		jsr		(a4)						; otherwise, call buffer flush function
		bcs.s	FormatHex_Return			; if buffer is terminated, branch
	endr

	rol.w	d2,d1

FormatHex_Word_WriteLastNibble:
	and.w	d3,d1						; get nibble
	move.b	HexDigitToChar(pc,d1), (a0)+
	dbf		d7, FormatHex_Return
	jmp		(a4)						; call buffer flush function and return buffer status

FormatHex_Return:
	rts									; return buffer status

; ---------------------------------------------------------------
HexDigitToChar:
	dc.b	'0123456789ABCDEF'
