
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Console Module
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; RAM structure
; ---------------------------------------------------------------

			rsreset
Console_RAM				equ		__rs
Console.ScreenPosReq	rs.l	1				;		screen position request for VDP
Console.CharsPerLine	rs.w	1				; d2	number of characters per line
Console.CharsRemaining	rs.w	1				; d3	remaining number of characters
Console.BasePattern		rs.w	1				; d4	base pattern
Console.ScreenRowSz		rs.w	1				; d6	row size within screen position
Console.Magic			rs.w	1				;		should contain a magic string to ensure this is valid console memory area
Console_RAM.size		equ		__rs-Console_RAM

; Drawing flags supported in strings
_newl	equ		$E0
_cr		equ		$E6
_pal0	equ		$E8
_pal1	equ		$EA
_pal2	equ		$EC
_pal3	equ		$EE

_setw	equ		$F0
_setoff	equ		$F4
_setpat	equ		$F8
_setx	equ		$FA

_ConsoleMagic	equ	'CO'

; ===============================================================
; ---------------------------------------------------------------
; Initialize console module
; ---------------------------------------------------------------
; INPUT:
;		a1		Console config
;		a2		Console font graphics (1bpp)
;		a3		Console RAM pointer
;
; OUTPUT:
;		d5	.l	Current on-screen position
;
; USES:
;		d0-d4, a5-a6
; ---------------------------------------------------------------

Console_Init:
	lea		VDP_Ctrl, a5
	lea		-4(a5), a6

	; Load console font
	@font_prg_loop:
		tst.w	(a1)
		bmi.s	@font_done
		move.l	(a1)+, (a5)				; VDP => Setup font offset in VRAM
		lea		(a2), a0				; load font offset
		move.w	(a0)+, d4				; load font size - 1
		jsr		Decomp1bpp(pc)			; decompress font (input: a0-a1/a6, uses: a0/d0-d4)
		lea		$20(a1), a1
		bra.s	@font_prg_loop

@font_done:
	addq.w	#2, a1					; skip end marker

	; Init Console RAM
	move.l	a3, usp					; remember Console RAM pointer in USP to restore it in later calls
	move.l	(a1)+, d5				; d4 = start VRAM pos
	move.l	d5,	(a3)+				; Console RAM => copy screen position (long)
	move.l	(a1)+, (a3)+			; Console RAM => copy number of characters per line (word) + characters remaining for the current line (word)
	move.l	(a1)+, (a3)+			; Console RAM => copy base pattern (word) + screen row size (word)
	move.w	#_ConsoleMagic, (a3)+ 	; Console RAM => set magic string

	; WARNING! Don't touch d5 from now on

	; Clear screen
	lea		Console_FillTile(pc), a3
	move.l	d5, (a5)				; VDP => Setup VRAM for screen namespace
	moveq	#0, d0					; d0 = fill pattern
	move.w	(a1)+, d1				; d1 = size of screen in tiles - 1
	jsr		(a3)					; fill screen
	vram	$0000, (a5)				; VDP => Setup VRAM at tile 0
	moveq	#0, d1					; d1 = number of tiles to fill - 1
	jsr		(a3)					; clear first tile


Console_LoadPalette: __global

	; Load palette
	cram	$00, (a5)				; VDP => Setup CRAM write at offset $00
	moveq	#0, d0					; d0 = black color
	moveq	#4-1, d3				; d3 = number of palette lines - 1

	@fill_palette_line:
		move.w	d0, (a6)			; transparent color is always black
		move.w	(a1)+, d2			; get CRAM data entry
	@0:	move.w	d2, (a6)			; write to CRAM
		move.w	(a1)+, d2			; get next CRAM data entry
		bpl.s	@0					; if color, branch

		moveq	#0, d1
		jsr		$10(a3,d2)			; fill the rest of cram by a clever jump (WARNING! Precision required!)
		dbf		d3, @fill_palette_line

	; Finalize
	move.w	#$8174, (a5)			; VDP => Enable display
	move.l	d5, (a5)				; VDP => Enable console for writing
	rts

; ---------------------------------------------------------------
Console_FillTile:
	rept 8
		move.l	d0, (a6)
	endr
	dbf		d1, Console_FillTile
	rts


; ===============================================================
; ---------------------------------------------------------------
; Setup console cursor position based on XY coordinates
; ---------------------------------------------------------------
; INPUT:
;		d0	.w	X-position
;		d1	.w	Y-position
; ---------------------------------------------------------------

Console_SetPosAsXY_Stack: __global
	movem.w	4(sp), d0-d1

Console_SetPosAsXY: __global
	movem.l	d1-d2/a3, -(sp)
	move.l	usp, a3
	cmp.w	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.w	(a3), d2
	and.w	#$E000, d2				; clear out displacement, leave base offset only
	mulu.w	Console.ScreenRowSz(a3), d1
	add.w	d1, d2
	add.w	d0, d2
	add.w	d0, d2
	move.w	d2, (a3)
	move.l	(a3)+, VDP_Ctrl

	move.w	(a3)+, (a3)+			; Reset remaining characters counter

@quit:
	movem.l	(sp)+, d1-d2/a3
	rts


; ===============================================================
; ---------------------------------------------------------------
; Get current line position in XY-coordinates
; ---------------------------------------------------------------
; OUTPUT:
;		d0	.w	X-position
;		d1	.w	Y-position
; ---------------------------------------------------------------

Console_GetPosAsXY: __global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.w	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit
	moveq	#0, d1
	move.w	(a3), d1
	and.w	#$1FFF, d1						; clear out base offset, leave displacement only
	divu.w	Console.ScreenRowSz(a3), d1		; d1 = row
	move.l	d1, d0
	swap	d0
	lsr.w	d0
@quit:
	move.l	(sp)+, a3
	rts

; ===============================================================
; ---------------------------------------------------------------
; Subroutine to transfer console to a new line
; ---------------------------------------------------------------

Console_StartNewLine: __global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.w	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.w	d0, -(sp)
	move.w	(a3), d0
	add.w	Console.ScreenRowSz(a3), d0
	; TODOh: Check if offset is out of plane boundaries
	and.w	#$5FFF, d0			; make sure line stays within plane
	move.w	d0, (a3)			; save new position
	move.l	(a3)+, VDP_Ctrl
	move.w	(a3)+, (a3)+		; reset characters on line counter (copy "CharsPerLine" to "CharsRemaining")

	move.w	(sp)+, d0
@quit:
	move.l	(sp)+, a3
	rts


; ===============================================================
; ---------------------------------------------------------------
; Subroutine to set console's base pattern
; ---------------------------------------------------------------
; INPUT:
;		d1	.w	Base pattern
; ---------------------------------------------------------------

Console_SetBasePattern: __global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.w	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit
	move.w	d1, Console.BasePattern(a3)
	
@quit:
	move.l	(sp)+, a3
	rts

; ===============================================================
; ---------------------------------------------------------------
; Subroutine to set console's base pattern
; ---------------------------------------------------------------
; INPUT:
;		d1	.w	Base pattern
; ---------------------------------------------------------------

Console_SetWidth: __global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.w	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit
	addq.w	#4, a3
	move.w	d1, (a3)+
	move.w	d1, (a3)+

@quit:
	move.l	(sp)+, a3
	rts


; ---------------------------------------------------------------
; Subroutine to draw string on screen
; ---------------------------------------------------------------
; INPUT:
;		a0		Pointer to null-terminated string
;		d1	.w	Base pattern (*_WriteLine_WithPattern only)
;
; OUTPUT:
;		a0		Pointer to the end of string
;
; MODIFIES:
;		a0
; ---------------------------------------------------------------

Console_WriteLine_WithPattern: __global
	bsr.s	Console_SetBasePattern

; ---------------------------------------------------------------
Console_WriteLine: __global
	pea		Console_StartNewLine(pc)

; ---------------------------------------------------------------
Console_Write: __global
	movem.l	d1-d6/a3/a6, -(sp)
	move.l	usp, a3
	cmp.w	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	; Load console variables
	move.l	(a3)+, d5			; d5 = VDP screen position request
	movem.w	(a3), d2-d4/d6		; d2 = number of characters per line

	swap	d6					; d3 = number of characters remaining until next line
								; d4 = base pattern
								; d6 = screen position increment value
	lea		VDP_Data, a6		; a6 = VDP_Data

	; First iteration in @loop, unrolled
	moveq	#0, d1
	move.b	(a0)+, d1			; load first char
	bgt.s	@loop				; if not a null-terminator or flag, branch
	bmi.s	@flag				; if char is a flague, branch

@done:
	movem.w	d2-d4, (a3)			; save d2-d4 (ignore d6 as it won't get changes anyways ...)
	move.l	d5, -(a3)			; save screen position
	
@quit:
	movem.l	(sp)+, d1-d6/a3/a6
	rts

; ---------------------------------------------------------------
	@loop:
		dbf		d3, @writechar
		add.w	d2, d3				; restore number of characters per line
		add.l	d6, d5
		bclr	#29, d5
		move.l	d5, 4(a6)			; setup screen position

	@writechar:
		add.w	d4, d1  			; add base pattern
		move.w	d1, (a6)			; draw

	@nextchar:
		moveq	#0, d1
		move.b	(a0)+, d1			; load next char
		bgt.s	@loop				; if not a null-terminator or flag, branch
		beq.s	@done				; if null-terminator, branch

	; Process drawing flag
@flag:
	and.w	#$1E, d1					; d2 = $00, $02, $04, $06, $08, $0A, $0C, $0E, $10, $12, $14, $16, $18, $1A, $1C, $1E
	jmp		@CommandHandlers(pc, d1)

; ---------------------------------------------------------------
@CommandHandlers:

	; For flags E0-EF (no arguments)
	add.l	d6, d5						; $00	; codes E0-E1 : start a new line
	moveq	#29, d1 					; $02	; codes E2-E3 : <<UNUSED>>
	bclr	d1, d5						; $04	; codes E4-E5 : <<UNUSED>>
	bra.s	@reset_line					; $06	; codes E6-E7 : reset position to the beginning of line
	bra.s	@set_palette_line_0			; $08	; codes E8-E9 : set palette line #0
	bra.s	@set_palette_line_1			; $0A	; codes EA-EB : set palette line #1
	bra.s	@set_palette_line_2			; $0C	; codes EC-ED : set palette line #2
	bra.s	@set_palette_line_3			; $0E	; codes EE-EF : set palette line #3

	; For flags F0-FF (one-byte arguments)
	move.b	(a0)+, d2					; $10	; codes F0-F1 : set characters per line, reset line
	bra.s	@reset_line					; $12	; codes F2-F3 : <<UNUSED>>
	move.b	(a0)+, d4					; $14	; codes F4-F5 : set low byte of base pattern (raw)
	bra.s	@nextchar					; $16	; codes F6-F7 : <<UNUSED>>
	bra.s	@set_base_pattern_high_byte	; $18	; codes F8-F9 : set high byte of base pattern (raw)
	move.b	(a0)+, d1					; $1A	; codes FA-FB : set x-position
	add.w	d1, d1						; $1C	; codes FC-FD : <<UNUSED>>
	moveq	#-$80, d3					; $1E	; codes FE-FF : <<UNUSED>>
	swap	d3							;
	and.l	d3, d5						;
	swap	d1							;
	or.l	d1, d5						;
;	bra.s	@reset_line					; restore d3 anyways, as it's corrupted

@reset_line:
	move.w	d2, d3
	move.l	d5, 4(a6)
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_0:
	and.w	#$7FF, d4
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_1:
	and.w	#$7FF, d4
	or.w	#$2000, d4
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_2:
	and.w	#$7FF, d4
	or.w	#$4000, d4
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_3:
	or.w	#$6000, d4
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_base_pattern_high_byte:
	move.w	d4, -(sp)
	move.b	(a0)+, (sp)
	move.w	(sp)+, d4
	bra.s	@nextchar


; ---------------------------------------------------------------
; Subroutine to provide writting of formatted strings
; ---------------------------------------------------------------
; INPUT:
;		a1		Pointer to source formatted string
;		a2		Arguments buffer pointer
;		a5		VDP Control port
;		a6		VDP Data port
;
; USES:
;		a0-a2, d7
; ---------------------------------------------------------------

Console_WriteLine_Formatted: __global
	pea		Console_StartNewLine(pc)

; ---------------------------------------------------------------
Console_Write_Formatted: __global

@buffer_size = $10

	move.l	a4, -(sp)

	lea		@FlushBuffer(pc), a4		; flushing function
	lea		-@buffer_size(sp), sp		; allocate string buffer
	lea		(sp), a0					; a0 = string buffer

	if def(__DEBUG__)
		move.l	a0, -4
	endc

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
; WARNING: This function shouldn't modify d0-d4 / a1-a3!
; ---------------------------------------------------------------

@FlushBuffer:
	clr.b	(a0)+					; finalize buffer

	neg.w	d7
	add.w	#@buffer_size-1, d7
	sub.w	d7, a0					; a0 = start of the buffer

	if def(__DEBUG__)
		cmpa.l	-4, a0
		beq.s	@align_ok
		move.l	-4, d0
		illegal
	@align_ok:
	endc

	move.l	a0, -(sp)
	jsr		Console_Write(pc)		; call the real flush function
	move.l	(sp)+, a0
	moveq	#@buffer_size-2, d7		; d7 = number of characters before flush -1
	rts								; WARNING! Must return Carry=0

