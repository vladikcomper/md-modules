
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Console Module
; ---------------------------------------------------------------

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
;		d0-d4, a0, a5-a6
; ---------------------------------------------------------------

Console_Init:	__global
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
		jsr		Console_FillTile+$10(pc,d2)			; fill the rest of cram by a clever jump (WARNING! Precision required!)
		dbf		d3, @fill_palette_line
	; fallthrough

; ---------------------------------------------------------------
; A shorter initialization sequence used by sub-consoles sharing
; the same palette and graphics, but using a different nametable
; 
; Also clears and resets console to the initial config
; ---------------------------------------------------------------
; INPUT:
;		a1		Initial console config
;		a3		Console RAM pointer
;		a5		VDP Control Port ($C00004)
;		a6		VDP Data Port ($C00000)
;
; OUTPUT:
;		d5	.l	Current on-screen position
;
; USES:
;		d0-d1, a1, a3
; ---------------------------------------------------------------

Console_InitShared:	__global
	move.l	a1, Console.VRAMConfigPtr(a3)	; Console RAM => Save VRAM config pointer
	;fallthrough

; ---------------------------------------------------------------
; Clears and resets console screen to the initial state
; ---------------------------------------------------------------
; INPUT:
;		a1		Initial console config
;		a3		Console RAM pointer
;		a5		VDP Control Port ($C00004)
;		a6		VDP Data Port ($C00000)
;
; OUTPUT:
;		d5	.l	Current on-screen position
;
; USES:
;		d0-d1, a1, a3
; ---------------------------------------------------------------

Console_Reset:	__global
	move.l	(a1)+, d5						; d5 = VDP command with start on-screen position
	moveq	#0, d0
	move.l	(a1)+, (a5)						; VDP => Setup VRAM write to HScroll
	move.l	d0, (a6)						; VDP => Reset HScroll (both planes)
	move.l	#$00104000, d1
	add.w	(a1)+, d1
	swap	d1
	move.l	d1, (a5)						; VDP => Setup VSRAM write
	move.l	d0, (a6)						; VDP => Reset VScroll (both planes)

	; Init Console RAM
	move.l	a3, usp							; remember Console RAM pointer in USP to restore it in later calls
	move.l	d5,	(a3)+						; Console RAM => set current position (long)
	move.l	d5,	(a3)+						; Console RAM => set start-of-line position (long)
	move.l	(a1)+, (a3)+					; Console RAM => copy number of characters per line (word) + characters remaining for the current line (word)
	move.l	(a1)+, (a3)+					; Console RAM => copy base pattern (word) + screen row size (word)
	move.w	d0, (a3)+						; Console RAM => clear Y- and X-tile scrolling
	move.b	#_ConsoleMagic, (a3)+			; Console RAM => set magic number

	; Clear screen
	move.l	d5, (a5)						; VDP => Setup VRAM for screen namespace
	;moveq	#0, d0							; d0 = fill pattern		-- OPTIMIZED OUT
	move.w	(a1)+, d1						; d1 = size of screen in tiles - 1
	bsr.s	Console_FillTile				; fill screen

	vram	$0000, (a5)						; VDP => Setup VRAM at tile 0
	;moveq	#0, d0							; d0 = fill pattern		-- OPTIMIZED OUT
	moveq	#0, d1							; d1 = number of tiles to fill - 1
	bsr.s	Console_FillTile				; clear first tile

	; Finalize
	move.w	#$8174, (a5)					; VDP => Enable display
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
; Clears the entire console and reset it to the initial state
; ---------------------------------------------------------------

Console_Clear:	__global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	movem.l	d0-d1/d5/a1/a5-a6, -(sp)
	lea		VDP_Ctrl, a5
	lea		-4(a5), a6
	movea.l	Console.VRAMConfigPtr(a3), a1
	jsr		Console_Reset(pc)
	movem.l	(sp)+, d0-d1/d5/a1/a5-a6

@quit:
	move.l	(sp)+, a3
	rts

; ===============================================================
; ---------------------------------------------------------------
;
; ---------------------------------------------------------------
; INPUT:
;		d0	.b	X-tile scrolling
;		d1	.b	Y-tile scrolling
; ---------------------------------------------------------------

Console_SetXYTileScrollPosition:	__global
	KDebug.WriteLine "Console_SetXYTileScrollPosition: x=%<.b d0>, y=%<.b d1>"

	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.l	d2, -(sp)
	move.l	a6, -(sp)
	lea		VDP_Data, a6

	move.b	d0, Console.XScrollTile(a3)
	move.b	d1, Console.YScrollTile(a3)

	move.w	Console.ScreenRowSz(a3), d2			; d2 = number of bytes in a row (usually $80)
	lsr.w	d2									; d2 = number of tiles in a row (usually $40)
	subq.w	#1, d2								; d2 = number of tiles in a row as a mask (usually $3F)
	movea.l	Console.VRAMConfigPtr(a3), a3		; a3 = VRAM config pointer
	addq.w	#4, a3								; skip screen start address
	move.l	(a3)+, 4(a6)						; VDP => Set HSRAM address
	and.b	d0, d2
	lsl.w	#3, d2								; d2 = HScroll value in pixels
	neg.w	d2									; ''
	move.w	d2, (a6)							; VDP => Set HScroll value
	move.w	d2, (a6)							; ''

	move.l	#$00104000, d2
	add.w	(a3)+, d2
	swap	d2
	move.l	d2, 4(a6)							; VDP => Set VSRAM address
	moveq	#$3F, d2
	and.b	d1, d2
	lsl.w	#3, d2								; d2 = VScroll value in pixels
	move.w	d2, (a6)							; VDP => Set VScroll value
	move.w	d2, (a6)							; ''
	;KDebug.WriteLine "data=%<.w d2>"

	move.l	(sp)+, d2
	move.l	(sp)+, a6

@quit:
	move.l	(sp)+, a3
	rts

; ===============================================================
; ---------------------------------------------------------------
; 
; ---------------------------------------------------------------
; OUTPUT:
;		d0	.b	X-tile scrolling
;		d1	.b	Y-tile scrolling
; ---------------------------------------------------------------

Console_GetXYTileScrollPosition:	__global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.b	Console.XScrollTile(a3), d0
	move.b	Console.YScrollTile(a3), d1

@quit:
	move.l	(sp)+, a3
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
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.w	Console.ScreenRowReq(a3), d2
	and.w	#$E000, d2						; clear out displacement, leave base offset only
	mulu.w	Console.ScreenRowSz(a3), d1
	add.w	d1, d2
	add.w	d0, d2
	add.w	d0, d2
	move.w	d2, (a3)						; Console RAM => update current position
	move.w	d2, Console.ScreenRowReq(a3)	; Console RAM => update start-of-line position
	addq.w	#8, a3
	move.w	(a3)+, (a3)+					; Reset remaining characters counter

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
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
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
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	move.w	d0, -(sp)
	move.w	Console.ScreenRowReq(a3), d0
	add.w	Console.ScreenRowSz(a3), d0
	; TODOh: Check if offset is out of plane boundaries
	and.w	#$5FFF, d0			; make sure line stays within plane
	move.w	d0, (a3)						; Console RAM => update current position
	move.w	d0, Console.ScreenRowReq(a3)	; Console RAM => update start-of-line position
	addq.w	#8, a3
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
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit
	move.w	d1, Console.BasePattern(a3)

@quit:
	move.l	(sp)+, a3
	rts

; ===============================================================
; ---------------------------------------------------------------
; Subroutine to set console's width
; ---------------------------------------------------------------
; INPUT:
;		d1	.w	Width to set
; ---------------------------------------------------------------

Console_SetWidth: __global
	move.l	a3, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit
	addq.w	#8, a3
	move.w	d1, (a3)+
	move.w	d1, (a3)+

@quit:
	move.l	(sp)+, a3
	rts


; ===============================================================
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
	movem.l	d1-d7/a3/a6, -(sp)
	move.l	usp, a3
	cmp.b	#_ConsoleMagic, Console.Magic(a3)
	bne.s	@quit

	; Load console variables
	movem.l	(a3)+, d5/d7		; d5 = VDP request: current position
								; d7 = VDP request: start-of-line position
	movem.w	(a3), d2-d4/d6		; d2 = number of characters per line

	swap	d6					; d3 = number of characters remaining until next line
								; d4 = base pattern
								; d6 = screen position increment value
	lea		VDP_Data, a6		; a6 = VDP_Data
	move.l	d5, 4(a6)			; VDP => set current position
	swap	d5

	; First iteration in @loop, unrolled
	moveq	#0, d1
	move.b	(a0)+, d1			; load first char
	bgt.s	@loop				; if not a null-terminator or flag, branch
	bmi.s	@flag				; if char is a flague, branch

@done:
	movem.w	d2-d4, (a3)			; save d2-d4 (ignore d6 as it won't get changes anyways ...)
	swap	d5
	movem.l	d5/d7, -(a3)		; save current and start-of-line positions

@quit:
	movem.l	(sp)+, d1-d7/a3/a6
	rts

; ---------------------------------------------------------------
	@loop:
		dbf		d3, @writechar
		add.w	d2, d3				; restore number of characters per line
		add.l	d6, d7
		bclr	#29, d7
		move.l	d7, 4(a6)			; setup screen position
		move.l	d7, d5				; current position = start-of-line position
		swap	d5

	@writechar:
		add.w	d4, d1  			; add base pattern
		move.w	d1, (a6)			; draw
		addq.w	#2, d5				; next character position

	@nextchar:
		moveq	#0, d1
		move.b	(a0)+, d1			; load next char
		bgt.s	@loop				; if not a null-terminator or flag, branch
		beq.s	@done				; if null-terminator, branch

	; Process drawing flag
@flag:
	and.w	#$1E, d1					; d1 = $00, $02, $04, $06, $08, $0A, $0C, $0E, $10, $12, $14, $16, $18, $1A, $1C, $1E
	jmp		@CommandHandlers(pc, d1)

; ---------------------------------------------------------------
@CommandHandlers:

	; For flags E0-EF (no arguments)
	add.l	d6, d7						; $00	; codes E0-E1 : start a new line
	moveq	#29, d1 					; $02	; codes E2-E3 : <<UNUSED>>
	bclr	d1, d7						; $04	; codes E4-E5 : <<UNUSED>>
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
	and.l	d3, d7						;
	swap	d1							;
	or.l	d1, d7						;
;	bra.s	@reset_line					; restore d3 anyways, as it's corrupted

@reset_line:
	move.w	d2, d3
	move.l	d7, 4(a6)
	move.l	d7, d5						; current position = start-of-line position
	swap	d5
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_0:
	and.w	#$9FFF, d4					; clear palette bits (resets to line 0)
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_1:
	and.w	#$9FFF, d4					; clear palette bits
	or.w	#$2000, d4					; set palette bits to %01 (line 1)
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_2:
	and.w	#$9FFF, d4					; clear palette bits
	or.w	#$4000, d4					; set palette bits to %10 (line 2)
	bra.s	@nextchar

; ---------------------------------------------------------------
@set_palette_line_3:
	or.w	#$6000, d4					; set palette bits to %11 (line 3)
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
;
; USES:
;		a0-a2, d7
; ---------------------------------------------------------------

Console_WriteLine_Formatted: __global
	pea		Console_StartNewLine(pc)

; ---------------------------------------------------------------
Console_Write_Formatted: __global

@buffer_size = __CONSOLE_TEXT_BUFFER_SIZE__

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
	jsr		Console_Write(pc)		; call the real flush function
	move.l	(sp)+, a0
	moveq	#@buffer_size-2, d7		; d7 = number of characters before flush -1
	rts								; WARNING! Must return Carry=0

