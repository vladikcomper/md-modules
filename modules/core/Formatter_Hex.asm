
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
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
	
	dbf		d7, FormatHex_Word_WriteLastNibble2
	jsr		(a4)
	bcc.s	FormatHex_Word_WriteLastNibble2
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

	__it:	= 0
	rept 4-1
	__it:	= __it+1
		rol.w	#4, d1
		moveq	#$F, d4
		and.w	d1, d4								; get nibble
		move.b	HexDigitToChar(pc,d4), (a0)+
		dbf		d7, FormatHex_Word_Nibble\#__it		; if buffer is not exhausted, branch
		jsr		(a4)								; otherwise, call buffer flush function
		bcs.s	FormatHex_Return					; if buffer is terminated, branch
	FormatHex_Word_Nibble\#__it:					; set label for the next nibble
	endr

FormatHex_Word_WriteLastNibble:
	rol.w	#4, d1
	moveq	#$F, d3

FormatHex_Word_WriteLastNibble2:
	and.w	d3, d1						; get nibble
	move.b	HexDigitToChar(pc,d1), (a0)+
	dbf		d7, FormatHex_Return
	jmp		(a4)						; call buffer flush function and return buffer status

FormatHex_Return:
	rts									; return buffer status

; ---------------------------------------------------------------
HexDigitToChar:
	dc.b	'0123456789ABCDEF'

; ---------------------------------------------------------------
FormatHex_LongWord_Trim:
	swap	d1
	beq.s	FormatHex_Word_Trim_Swapped		; if high word is 0000, we only have to display the lower one

FormatHex_LongWord_Trim_Swapped_NonZero:
	bsr.s	FormatHex_Word_Trim
	bcs.s	FormatHex_Return				; if buffer terminated, branch
	bra		FormatHex_Word_Swapped			; should display a word without trimming now

FormatHex_Word_Trim_Swapped:
	swap	d1

; ---------------------------------------------------------------
FormatHex_Word_Trim:

	__it:	= 0
	rept 4-2
	__it:	= __it+1

		rol.w	#4, d1
		moveq	#$F, d4
		and.w	d1, d4
		beq.s	FormatHex_Word_Trim_Nibble\#__it		; if nibble is 0, check next nibble (don't draw)

		; If we get to this point, we are going to branch to "non-trim" routines from now on ...
		move.b	HexDigitToChar(pc,d4), (a0)+			; output digit
		dbf		d7, FormatHex_Word_Nibble\#__it			; if buffer is not exhausted, branch to normal nibble drawing routine
		jsr		(a4)									; otherwise, call buffer flush function
		bcc.s	FormatHex_Word_Nibble\#__it				; if buffer is not terminated, branch to normal nibble drawing routine
		rts

	FormatHex_Word_Trim_Nibble\#__it:
	endr

	; Pre-last iteration is special as it connects with `FormatHex_Word_WriteLastNibble`
	rol.w	#4, d1
	moveq	#$F, d4
	and.w	d1, d4
	beq.s	FormatHex_Word_WriteLastNibble			; even if this nibble is 0, the last one is rendered anyways
	move.b	HexDigitToChar(pc,d4), (a0)+
	dbf		d7, FormatHex_Word_WriteLastNibble	; if buffer is not exhausted, branch
	jsr		(a4)									; otherwise, call buffer flush function
	bcc.s	FormatHex_Word_WriteLastNibble			; if buffer is not terminated, branch
	rts
