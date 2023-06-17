
; =============================================================================
; -----------------------------------------------------------------------------
; Backtrace debugger
;
; (c) 2023, Vladikcomper
; -----------------------------------------------------------------------------

		include	"..\core\Console.defs.asm"		; for "_pal0", "_newl" etc

; -----------------------------------------------------------------------------
Debugger_Backtrace:
		; Setup screen header (position and "Backtrace:" text)
		lea		Str_ScreenHeader(pc), a0
@_inj0:	jsr		Console_Write(pc)

		; ----------------------------------------
		; Build backtrace routine
		; ----------------------------------------

		; Registers layout:
		@data0:			equr	d0
		@data1:			equr	d1
		@addr0:			equr	a0
		@stack_top:		equr	a1
		@stack_curr:	equr	a2

		move.l	0.w, @stack_top
		subq.l	#4, @stack_top					; set final longword to read
		lea		(sp), @stack_curr
@_inj1:	jsr		Error_MaskStackBoundaries(pc)

		cmpa.l	@stack_curr, @stack_top			; are we within stack?
		blo.s	@done							; if not, branch

	@try_offset_loop:
			cmpi.w	#$40, (@stack_curr)				; is address within ROM ($000000..$3FFFFF)?
			bhs.s	@try_next_offset				; if not, branch
			move.l	(@stack_curr), @data0			; @data0 = possible return address
			beq.s	@try_next_offset				; if address is zero, branch
			movea.l	@data0, @addr0					; @addr0 = possible return address
			andi.w	#1, @data0						; is address even?
			bne.s	@try_next_offset				; if not, branch

			; Trying to find JSR/BSR instructions before the return address
		@chk_2byte:
			; 2-byte instructions:
			move.b	-(@addr0), @data1
			move.b	-(@addr0), @data0

		@chk_2byte_bsr:
			; BSR.s = %01000001 XXXXXXXX
			cmp.b	#$61, @data0					; is instruction BSR.s?
			bne.s	@chk_2byte_jsr					; if not, branch
			tst.b	@data1							; BSR.s must use non-zero displacement
			bne.s	@offset_is_caller				; if yes, branch

		@chk_2byte_jsr:
			; JSR (an) = %01001110 10010XXX
			cmp.b	#$4E, @data0					; is instruction JSR?
			bne.s	@chk_4byte						; if not, branch
			and.b	#%11111000, @data1				; clear out "EARegister" part
			cmp.b	#%10010000, @data1				; is mode (an)?
			beq.s	@offset_is_caller				; if yes, branch

		@chk_4byte:
			move.w	-(@addr0), @data0

		@chk_4byte_bsr:
			; BSR.w	= %01000001 00000000 XXXXXXXX XXXXXXXX
			cmp.w	#$6100, @data0					; is instruction BSR.w?
			beq.s	@offset_is_caller				; if yes, branch

		@chk_4byte_jsr:
			; JSR d16(an)	= %01001110 10101XXX XXXXXXXX XXXXXXXX
			; JSR d8(an,xn)	= %01001110 10110XXX XXXXXXXX XXXXXXXX
			; JSR (xxx).w	= %01001110 10111000 XXXXXXXX XXXXXXXX
			; JSR d16(pc)	= %01001110 10111010 XXXXXXXX XXXXXXXX
			; JSR d8(pc,xn)	= %01001110 10111011 XXXXXXXX XXXXXXXX
			move.b	@data0, @data1
			clr.b	@data0
			cmpi.w	#$4E00, @data0					; is instruction JSR?
			bne.s	@chk_6byte						; if not, branch
			cmp.b	#%10101000, @data1				; low byte should be between %10101000
			blo.s	@chk_6byte
			cmp.b	#%10111011, @data1				; ... and %10111011
			bhi.s	@chk_6byte
			cmp.b	#%10111001, @data1				; JSR (xxx).l is invalid, because it's not 4 bytes!
			bne.s	@offset_is_caller

		@chk_6byte:
		@chk_6byte_jsr:
			; JSR (xxx).l	= %01001110 10111001 XXXXXXXX XXXXXXXX
			cmp.w	#%0100111010111001, -(@addr0)	; is instruction JSR (xxx).l?
			bne.s	@try_next_offset				; if not, branch

		@offset_is_caller:
			move.l	@stack_curr, -(sp)
			move.l	@stack_top, -(sp)
			move.l	@addr0, d1						; d1 = offset
@_inj2:		jsr		Error_DrawOffsetLocation2(pc)
			move.l	(sp)+, @stack_top
			move.l	(sp)+, @stack_curr

			addq.l	#2, @stack_curr					; for +4 (see below)

		@try_next_offset:
			addq.l	#2, @stack_curr
			cmpa.l	@stack_curr, @stack_top
			bhs		@try_offset_loop

	@done:
		rts

; -----------------------------------------------------------------------------
Str_ScreenHeader:
		dc.b	_newl, _setx, 1, _setw, 38
		dc.b	_pal1, 'Backtrace:', _newl, _newl, 0
		even

__blob_end:

; =============================================================================
; -----------------------------------------------------------------------------
; Injectable routines for a stand-alone build
; -----------------------------------------------------------------------------
; NOTE:
;	Those point to illegal instruction just to make the code compile.
;	Each invocation of them marked with @_injX or __injX symbol will be
;	manually linked by BLOBTOASM utility using the injection map.
; -----------------------------------------------------------------------------

Console_Write:				equ		__ILLEGAL__
Error_MaskStackBoundaries:	equ		__ILLEGAL__
Error_DrawOffsetLocation2:	equ		__ILLEGAL__

__ILLEGAL__:
		illegal
