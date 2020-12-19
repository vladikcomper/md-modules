
_ValidHeader = $DEB2

; ===============================================================
; ---------------------------------------------------------------
; Subroutine to find nearest symbol for given offset
; ---------------------------------------------------------------
; INPUT:
;		d1	.l		Offset
;
; OUTPUT:
;		d0	.w		Status (0 = ok, -1 = error)
;		d1	.l		Offset displacement
;		a1			Pointer to compressed symbol text
;
; USES:
;		a1-a3 / d0-d3
; ---------------------------------------------------------------

GetSymbolByOffset:
	lea		SymbolData(pc), a1
	cmp.w	#_ValidHeader, (a1)+	; verify header
	bne.s	@return_error

	moveq	#-2, d0
	add.w	(a1)+, d0				; d0 = (lastBlock+1)*4
	moveq	#-4, d2					; d2 will be 4-byte boundary mask
	moveq	#0, d3					; d3 will be gain value

	swap	d1						; d1 = block
	and.w	#$FF, d1				; mask higher 8-bits of block id, since MD has 24-bit address bus anyways ...
	add.w	d1, d1					; d1 = block*2
	add.w	d1, d1					; d1 = block*4
	cmp.w	d0, d1					; is the offset's block within [0..lastBlock+1]?
	bhi.s	@return_error			; if not, branch
	beq.s	@load_prev_block		; if strictly lastBlock+1, fetch the previous one ...

	@load_block:
		move.l	(a1,d1), d0 			; d0 = relative offset
		beq.s	@load_prev_block		; if block is empty, branch
		lea 	(a1,d0.l), a3			; a3 = Block structure
		swap	d1						; d1 = offset

		moveq	#0, d0
		move.w	(a3)+, d0				; d0 = symbols heap relative offset
		cmp.w	(a3), d1				; compare the requested offset with the lowest in the block
		blo.s	@load_prev_block_2		; if even lower, find nearest offset in the previous block

		; WARNING: The following instruction assumes blocks will not be reloaded anymore
		lea		-2(a3,d0.l), a1			; a1 = symbols heap
										; d0 = (high - low)
		lea 	-4(a1), a2 				; a2 = high
										; a3 = low
		@search_loop:
			lsr.w	#1, d0					; 8		; d0 = (high - low) / 2
			and.w	d2, d0					; 4		; find nearest 4-byte struct for the displacement

			cmp.w	(a3,d0), d1				; 14	; compare the requested offset with the guessed entry
			blo.s	@search_lower_half		; 8/10
			bhi.s	@search_higher_half		; 8/10

			adda.w	d0, a3
			bra.s	@load_symbol

		; -----------------------------------------------------------
		@search_higher_half:
			lea 	4(a3,d0), a3			; 12	; limit "low" to "middle"+1 of previously observed area
			move.l	a2, d0					; 4
			sub.l	a3, d0					; 8		; d0 = (high - low)
			bpl.s	@search_loop			; 8/10	; if (low >= high), branch

			subq.w	#4, a3
			bra.s	@load_symbol

		; -----------------------------------------------------------
		@search_lower_half:
			lea 	-4(a3,d0), a2			; 12	; limit "high" to "middle"-1 of previously observed area
			move.l	a2, d0					; 4		;
			sub.l	a3, d0					; 8		; d0 = (high - low)
			bpl.s	@search_loop			; 8/10	; if (low >= high), branch

			lea		(a2), a3

		@load_symbol:
			sub.w	(a3)+, d1				; d1 = displacement
			moveq	#0, d2
			move.w	(a3)+, d2				; d2 = symbol pointer, relative to the heap
			adda.l	d2, a1

			swap	d1						; ''
			; NOTICE: You should be able to access SymbolData+4(pc,d1) now ...
			clr.w	d1						; ''
			swap	d1						; andi.l #$FFFF, d1
			add.l	d3, d1
			moveq	#0, d0					; return success
			rts

; ---------------------------------------------------------------
@return_error:
	moveq	#-1, d0				; return -1
	rts

	; ---------------------------------------------------------------
	@load_prev_block:
		swap	d1
	
	@load_prev_block_2:
		moveq	#0, d0
		move.w	d1, d0
		add.l	d0, d3				; increase offset gain by the offset within the previous block
		addq.l	#1, d3				; also increase offset gain by 1 to compensate for ...
		move.w	#$FFFF, d1			; ... setting offset to $FFFF instead of $10000
		swap	d1
		subq.w	#4, d1				; decrease block number
		bpl.s	@load_block			; if block is positive, branch
		moveq	#-1, d0				; return -1
		rts


; ===============================================================
; ---------------------------------------------------------------
; Subroutine to decode compressed symbol name to string buffer
; ---------------------------------------------------------------
; INPUT:
;		a0			String buffer pointer
;		a1			Pointer to the compressed symbol data
;
;		d7	.w	Number of bytes left in buffer, minus one
;		a0		String buffer
;		a4		Buffer flush function
;
; OUTPUT:
;		(a0)++	ASCII characters for the converted value
;
; USES:
;		a1-a3, d1-d4
; ---------------------------------------------------------------

DecodeSymbol:
	lea		SymbolData(pc), a3
	cmp.w	#_ValidHeader, (a3)+			; verify the header
	bne.s	@return_cc
	add.w	(a3), a3						; a3 = Huffman code table

	moveq	#0,d4							; d4 will handle byte feeding from bitstream

; ---------------------------------------------------------------
	@decode_new_node:
		moveq	#0, d1							; d1 will hold code
		moveq	#0, d2							; d2 will hold code length (in bits)
		lea		(a3), a2						; a2 will hold current position in the decode table

	; ---------------------------------------------------------------
	@code_extend:
		dbf 	d4, @stream_ok					; if bits remain in byte, branch
		move.b	(a1)+, d3
		moveq	#7, d4

	@stream_ok:
		add.b	d3, d3							; get a bit from the bitstream ...
		addx.w	d1, d1							; ... add it to current code
		addq.w	#1, d2							; count this bit

		@code_check_loop:
			cmp.w	(a2), d1 						; does this node has the same code?
			bhi.s	@code_check_next				; if not, check next
			blo.s	@code_extend					; if no nodes are found, branch
			cmp.b	2(a2), d2						; is this code of the same length?
			beq.s	@code_found 					; if not, branch
			blo.s	@code_extend					; if length is lower, append code
	
		@code_check_next:
			addq.w	#4, a2
			cmp.w	(a2), d1 						; does this node has the same code?
			bhi.s	@code_check_next				; if not, check next
			blo.s	@code_extend					; if no nodes are found, branch
			cmp.b	2(a2), d2						; is this code of the same length?
			blo.s	@code_extend					; if length is lower, append code
			bne.s	@code_check_next

	@code_found:
		move.b	3(a2), (a0)+					; get decoded character
		beq.s	@decode_done					; if it's null character, branch
		
		dbf		d7, @decode_new_node
		jsr		(a4)
		bcc.s	@decode_new_node
		rts

; ---------------------------------------------------------------
@decode_done:
	subq.w	#1, a0				; put the last character back
	rts

; ---------------------------------------------------------------
@return_cc:						; return with Carry clear (cc)
	moveq	#0,d0
	rts
