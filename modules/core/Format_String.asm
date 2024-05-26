
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; String formatter module
; ---------------------------------------------------------------
; INPUT:
;		a0		Pointer to a string buffer
;		a1		Pointer to format sequence
;		a2		Pointer to arguments list
;		a4		Buffer flush function
;		d7	.w	Number of bytes left in buffer, minus one
;
; USES:
;		a0-a2
; ---------------------------------------------------------------

FormatString_reglist	reg	d0-d4/a3
FormatString_regnum		equ	7

; ---------------------------------------------------------------
FormatString:	__global
	movem.l	FormatString_reglist, -(sp)

	; NOTICE: This loop shouldn't use registers D0/D1, as control codes B0..BF, C0..CF
	;	that are executed consequently use it to pass parameters inbetween.
	@copy_loop:
		move.b	(a1)+, (a0)+
		dble	d7, @copy_loop				; if character's code is below $80 and not $00, copy string ...
		bgt.s	@flush
		beq.s	@quit						; if char $00 was fetched, quit

	@flag:
		; Process special character
		move.b	-(a0), d3					; d3 = special character that was pushed out of the string
		moveq	#$70, d2					; d2 = $00, $10, $20, $30, $40, $60, $70
		and.b	d3, d2						; d2 = code offset based on character's code, aligned on $10-byte boundary
		jsr		FormatString_CodeHandlers(pc, d2)	; jump to an appropriate special character handler
		bcc.s	@copy_loop					; if string buffer is good, branch

	@quit_no_flush:
		movem.l	(sp)+, FormatString_reglist
		rts

	@flush:
		jsr		(a4)						; flush buffer
		bcc.s	@copy_loop					; if flashing was ok, branch
		bra.s	@quit_no_flush

@quit:
	subq.w	#1, a0							; set pointer to null character
	jsr		(a4)							; call flush buffer function
	movem.l	(sp)+, FormatString_reglist

@return:
	rts

; --------------------------------------------------------------
FormatString_CodeHandlers:

	; codes 80..8F : Display hex number
	lea		FormatHex_Handlers(pc), a3			; $00
	eor.b	d3, d2								; $04	; d2 = lower 4 bits of char code, encodes argument size (valid values are: 0, 1, 3, see below)
	add.b	d2, d2								; $06	; multiply 4-bit code by 2 as instructions in the code handlers below are word-sized
	jmp		@ArgumentFetchFlow(pc,d2)			; $08	; jump to an appropriate insturction (note that even invalid codes won't crash)
	nop											; $0C
	nop											; $0E

	; codes 90..9F : Display decimal number
	lea		FormatDec_Handlers(pc), a3			; $00
	eor.b	d3, d2								; $04	; d2 = lower 4 bits of char code, encodes argument size (valid values are: 0, 1, 3, see below)
	add.b	d2, d2								; $06	; multiply 4-bit code by 2 as instructions in the code handlers below are word-sized
	jmp		@ArgumentFetchFlow(pc,d2)			; $08	; jump to an appropriate insturction (note that even invalid codes won't crash)
	nop											; $0C
	nop											; $0E

	; codes A0..AF : Display binary number
	lea		FormatBin_Handlers(pc), a3			; $00
	eor.b	d3, d2								; $04	; d2 = lower 4 bits of char code, encodes argument size (valid values are: 0, 1, 3, see below)
	add.b	d2, d2								; $06	; multiply 4-bit code by 2 as instructions in the code handlers below are word-sized
	jmp		@ArgumentFetchFlow(pc,d2)			; $08	; jump to an appropriate instruction (note that even invalid codes won't crash)
@d0	subq.w	#1, a0								; $0C	; overwrite null-terminator (part of "String" section, see below)
	rts											; $0E

	; codes B0..BF : Display symbol
	lea		FormatSym_Handlers(pc), a3			; $00
	moveq	#3, d2								; $04
	and.b	d3, d2								; $06	; d2 = 0, 1, 3 ... (ignore handlers for signed values)
	add.w	d2, d2								; $08	; multiply 4-bit code by 2 as instructions in the code handlers below are word-sized
	jmp		@ArgumentFetchFlow(pc,d2)			; $0A	; jump to an appropriate instruction (note that even invalid codes won't crash)
	nop											; $0E

	; codes C0..CF : Display symbol's displacement (to be used after codes B0..BF, if extra formatting is due)
	tst.w	d0									; $00	; check "GetSymbolByOffset" (see "FormatSym" code)
	bmi.s	@c0									; $02	; if return code is -1 (error), assume d1 is OFFSET, display it directly
	tst.l	d1									; $04	; assume d1 is DISPLACEMENT, test it
	beq.s	@return2							; $06	; if displacement is zero, branch
	jmp		FormatSym_Displacement(pc)			; $08
@c0	jmp		FormatSym_Offset(pc)				; $0C

	; codes D0..DF : String
	movea.l	(a2)+, a3							; $00	; a3 = string ptr
@d1	move.b	(a3)+, (a0)+						; $02	; copy char
	dbeq	d7, @d1								; $04	; loop until either buffer ends or zero-terminator is met
	beq.s	@d0									; $08	; if met zero-terminator, branch
	jsr		(a4)								; $0A	; flush buffer
	bcc.s	@d1									; $0C	; if buffer is ok, branch
@return2:
	rts											; $0E	; return C

	; codes E0..EF : Drawing command (ignore)
	addq.w	#1, a0								; $00	; restore control character back
	bra.s	@AfterRestoreCharacter				; $02

	; NOTICE: Code handlers continue below and overlap with the following code ...

; --------------------------------------------------------------
; WARNING!
;	The code in the following blocks are critical and shouldn't
;	be altered anymore. Each instruction MUST take 2 bytes,
;	so even the invalid codes won't crash, but only break
;	the flow ...
; --------------------------------------------------------------

@ArgumentFetchFlow:
	addq.w	#8, a3							; $00 :$04	; code 0 : Display byte
	move.w	(a2)+, d1						; $02 :$06	; code 1 : Display word
	jmp		(a3)							; $04 :$08	; code 2 : ## invalid : displays garbage word
; --------------------------------------------------------------
	addq.w	#4, a3							; $06 :$0A	; code 3 : Display longword
	move.l	(a2)+, d1						; $08 :$0C	; code 4 : ## invalid ##: displays word, but loads longword
	jmp		(a3)							; $0A :$0E	; code 5 : ## invalid ##: displays garbage word
; --------------------------------------------------------------
	; codes F0..FF : Drawing command, one-byte argument (ignore, cut early if no enough space to fit argument)
	subq.w	#2, d7							; $0C :$00	; code 6 : ## invalid ##: restores 2 control characters if enough space
	bra.s	@RestoreTwoCharacters			; $0E :$02	; code 7 : ## invalid ##: restores 2 control characters, but check is broken
; --------------------------------------------------------------
	addq.w	#8, a3							; $10		; code 8 : Display signed byte
	move.w	(a2)+, d1						; $12		; code 9 : Display signed word
	bra.s	@CheckValueSign					; $14		; code A : ## invalid ##: displays garbage signed word
; --------------------------------------------------------------
	addq.w	#4, a3							; $16		; code B : Display signed longword
	move.l	(a2)+, d1						; $18		; code C : ## invalid ##: displays signed word, but loads longword
; --------------------------------------------------------------
@CheckValueSign:
	bpl.s	@SignPositive					; $1A		; code D : ## invalid ##: displays garbage signed word
	neg.l	d1								; $1C		; code E : ## invalid ##: displays gargage pseudo-negative word
	move.b	#'-', (a0)+						; $1E		; code F : ## invalid ##: displays gargage pseudo-non-negative word
	bra.s	@AfterSendSign

; --------------------------------------------------------------
@SignPositive:
	move.b	#'+', (a0)+

@AfterSendSign:
	dbf		d7, @sign_ok					; if there are characters left in the buffer, branch
	jsr		(a4)							; call buffer flush function
	bcs.s	@return2						; if there's no space left in buffer, quit

@sign_ok:
	jmp		(a3)							; draw the actual value using an appropriate handler

; --------------------------------------------------------------
@AfterRestoreCharacter:
	dbf		d7, @return2
	jmp		(a4)

; --------------------------------------------------------------
@RestoreTwoCharacters:
	bcs.s	@FlushBufferEarly				; if we had less than 2 characters remaining in buffer, cut it early: we'll fit it in the next buffer instead
	addq.w	#1, a0							; restore control character
	move.b	(a1)+, (a0)+					; store argument (next byte)
	rts										; return Carry=0

; --------------------------------------------------------------
@FlushBufferEarly:
	addq.w	#2, d7							; don't store last 2 characters: we won't fit them
	subq.w	#1, a1							; rewind source string to fetch flag again
	jmp		(a4)
