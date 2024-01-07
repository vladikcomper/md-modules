
; =============================================================================
; -----------------------------------------------------------------------------
; MD Debugger and Error Handler
;
; (c) 2016-2023, Vladikcomper
; -----------------------------------------------------------------------------
; KDebug intergration module
; -----------------------------------------------------------------------------

; =============================================================================
; -----------------------------------------------------------------------------
; Write formatted strings to KDebug message buffer
; -----------------------------------------------------------------------------
; INPUT:
;		a1		Pointer to source formatted string
;		a2		Arguments buffer pointer
;
; USES:
;		a0-a2, d7
; -----------------------------------------------------------------------------

KDebug_WriteLine_Formatted: __global
	pea		KDebug_FlushLine(pc)

; -----------------------------------------------------------------------------
KDebug_Write_Formatted: __global

@buffer_size = $10

	move.l	a4, -(sp)
	lea		@FlushBuffer(pc), a4		; flushing function
	lea		-@buffer_size(sp), sp		; allocate string buffer
	lea		(sp), a0					; a0 = string buffer
	moveq	#@buffer_size-2, d7			; d7 = number of characters before flush -1
	jsr		FormatString(pc)
	lea		@buffer_size(sp), sp		; free string buffer
	move.l	(sp)+, a4
	rts

; ---------------------------------------------------------------
; Flush buffer callback raised by FormatString
; ---------------------------------------------------------------
; INPUT:
;		a0		Buffer position
;		d7	.w	Number of characters remaining in buffer - 1
;
; OUTPUT:
;		a0		Buffer position after flushing
;		d7	.w	Number of characters before next flush - 1
;		Carry	0 = continue operation
;				1 = terminate FormatString with error condition
;
; WARNING: This function can only modify a0 / d7 !
; ---------------------------------------------------------------

@FlushBuffer:
	clr.b	(a0)+					; finalize buffer

	neg.w	d7
	add.w	#@buffer_size-1, d7
	sub.w	d7, a0					; a0 = start of the buffer

	move.l	a0, -(sp)
	move.l	a5, -(sp)

	lea		VDP_Ctrl, a5
	move.w	#$9E00, d7
	bra.s	@write_buffer_next

	@write_buffer:
		move.w	d7, (a5)

	@write_buffer_next:
		move.b	(a0)+, d7
		bgt.s	@write_buffer			; if not null-terminator or flag, branch
		beq.s	@write_buffer_done		; if null-terminator, branch
		sub.b	#_newl, d7				; is flag "new line"?
		beq.s	@write_buffer			; if yes, branch
		bra.s	@write_buffer_next		; otherwise, skip writing

	; -----------------------------------------------------------------------------
	@write_buffer_done:
	
	move.l	(sp)+, a5
	move.l	(sp)+, a0
	moveq	#@buffer_size-2, d7		; d7 = number of characters before flush -1
	rts								; WARNING! Must return Carry=0


; =============================================================================
; -----------------------------------------------------------------------------
; Finishes the current line and flushes KDebug message buffer
; -----------------------------------------------------------------------------

KDebug_FlushLine:	__global
	move.w	#$9E00, VDP_Ctrl			; send null-terminator
	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Write raw string to KDebug message buffer
; -----------------------------------------------------------------------------
; INPUT:
;		a0		Pointer to null-terminated string
;
; OUTPUT:
;		a0		Pointer to the end of string
;
; MODIFIES:
;		a0
; -----------------------------------------------------------------------------

KDebug_WriteLine:	__global
	pea		KDebug_FlushLine(pc)

; ---------------------------------------------------------------
KDebug_Write:	__global
	move.w	d7, -(sp)
	move.l	a5, -(sp)

	lea		VDP_Ctrl, a5
	move.w	#$9E00, d7
	bra.s	@write_buffer_next

	@write_buffer:
		move.w	d7, (a5)

	@write_buffer_next:
		move.b	(a0)+, d7
		bgt.s	@write_buffer			; if not null-terminator or flag, branch
		beq.s	@write_buffer_done		; if null-terminator, branch
		sub.b	#_newl, d7				; is flag "new line"?
		beq.s	@write_buffer			; if yes, branch
		bra.s	@write_buffer_next		; otherwise, skip writing

	; -----------------------------------------------------------------------------
	@write_buffer_done:
	move.l	(sp)+, a5
	move.w	(sp)+, d7
	rts
