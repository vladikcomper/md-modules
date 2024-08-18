
; =============================================================================
; -----------------------------------------------------------------------------
; MD Debugger and Error Handler
;
; (c) 2016-2024, Vladikcomper
; -----------------------------------------------------------------------------
; Error Handler Screen
; -----------------------------------------------------------------------------

	if def(__LINKABLE__)
		section	rom
	endif

	include	'..\core\Macros.asm'
	include	'..\core\KDebug.defs.asm'
	include	'..\core\Console.defs.asm'
	include	'..\core\Format_String.defs.asm'


; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------

VRAM_Font:			equ 	(('!'-1)*$20)
VRAM_ErrorScreen:	equ		$8000
VRAM_ErrorHScroll:	equ		$FC00
VSRAM_ErrorVScroll:	equ		$00

_white:				equ 	0
_yellow: 			equ 	1<<13
_blue:				equ 	2<<13
_blue2:				equ 	3<<13


; =============================================================================
; -----------------------------------------------------------------------------
; Main error handler
; -----------------------------------------------------------------------------
; GLOBAL REGISTERS:
;		d6	.b	Error handler flags bitfield
;		a3		Pointer to additional parameters
;		a4		Stack pointer (after exception frame)
;
; NOTE:	It should be called via JSR/BSR exclusively with error information
;		following the JSR/BSR opcode.
;		Alternatively, use PEA with pointer to error information followed
;		by JMP.
;
; ERROR DATA FORMAT:
;		dc.b	"<Error formatted message>", 0
;		dc.b	<Error Handler flags>
;		even
;		jmp		<ConsoleProgram> (optional)
;
;	Flags bitfield uses the following format:
;		bit #0:	If set, loads extended stack frame
;				(used for Address and Bus errors only)
;		bit #1: If set, displays SR and USP registers
;		bit #2:	<UNUSED>
;		bit #3:	<UNUSED>
;		bit #4:	<UNUSED>
;		bit #5:	If set, displays full screen, but then calls console program
;				(via "jmp <ConsoleProgram>")
;		bit #6:	If set, displays error header only, then calls console program
;				(via "jmp <ConsoleProgram>")
;		bit #7:	If set, skips a byte after this byte, so
;				jmp <ConsoleProgram> is word-aligned.
; -----------------------------------------------------------------------------

ErrorHandler:	__global
	move	#$2700, sr						; disable interrupts for good

	KDebug.WriteLine "Entered Error Handler..."

	lea		-Console_RAM.size(sp), sp		; STACK => allocate memory for console
	movem.l d0-a6, -(sp) 					; STACK => dump registers ($3C bytes)

	jsr		ErrorHandler_SetupVDP(pc)
	lea 	$3C+Console_RAM.size(sp), a4	; a4 = arguments, stack frame

	move.l	usp, a0
	move.l	a0, -(sp)						; save USP if needed to display later (as it's overwritten by the console subsystem)

	; Initialize console subsystem
	lea		$3C+4(sp), a3					; a3 = Console RAM
	jsr		Error_InitConsole(pc)

	; ----------------
	; Screen header
	; ----------------

	lea		Str_SetErrorScreen(pc), a0
	jsr		Console_Write(pc)

	; Print error description
	movea.l	(a4)+, a1						; get error text
	lea		(a4), a2						; a2 = load arguments buffer (if present)
	jsr 	Console_WriteLine_Formatted(pc)
	jsr		Console_StartNewLine(pc)

	lea		(a2), a4						; a4 = stack frame (after arguments buffer was processed by Console_Write)

	; Load screen configuration bitfield
	move.b	(a1)+, d6						; d6 = configuration bitfield
	bpl.s	@align_ok						; if "_eh_align_offset" is not set, branch
	addq.w	#1, a1							; skip a byte to avoid address error on reading the next word
@align_ok:
	lea		(a1), a3						; a3 may be used to fetch console program address later

	; Print error address (for Address error and Bus Error only)
	btst	#0, d6							; does error has extended stack frame (Address Error and Bus Error only)?
	beq.s	@skip							; if not, branch

	lea 	Str_Address(pc), a0				; a0 = label string
	move.l	2(a4), d1						; d1 = address error offset
	jsr		Error_DrawOffsetLocation(pc)
	addq.w	#8, a4							; skip extension part of the stack frame
@skip:

	; Print exception offset
	lea 	Str_Offset(pc), a0				; a0 = label string
	move.l	2(a4), d1						; d1 = last return offset
	jsr		Error_DrawOffsetLocation(pc)

	; Print caller
	movea.l	0.w, a1							; a1 = stack top boundary
	lea		6(a4), a2						; a2 = call stack (after exception stack frame)
	jsr		Error_GuessCaller(pc)			; d1 = caller
	lea 	Str_Caller(pc), a0				; a0 = label string
	jsr		Error_DrawOffsetLocation(pc)

	jsr		Console_StartNewLine(pc)

	btst	#6, d6							; is execute console program bit set?
	bne.w	Error_EnterConsoleProgram		; if yes, branch to error trap

	; ----------------
	; Registers
	; ----------------

	lea		4(sp), a2						; use register buffer as arguments

	; Print data registers
	jsr		Console_GetPosAsXY(pc)			; d0/d1 = XY-pos
	move.w	d1, -(sp)						; remember line
	moveq	#3, d0							; left margin for data registers
	jsr		Console_SetPosAsXY(pc)
	move.w	#'d0', d0						; d0 = 'd0', what a twist !!!
	moveq	#8-1, d5						; number of registers - 1
	jsr		Error_DrawRegisters(pc)

	; Print address registers
	move.w	(sp)+, d1						; restore line
	moveq	#$11, d0						; left margin for address registers
	jsr		Console_SetPosAsXY(pc)
	move.w	#'a0', d0
	moveq	#7-1, d5						; number of registers - 1
	jsr		Error_DrawRegisters(pc)

	; Special case : stack pointer (SP)
	move.w	#'sp', d0
	moveq	#0, d5							; number of registers - 1
	move.l	a4, -(sp)
	lea		(sp), a2
	jsr		Error_DrawRegisters(pc)
	addq.w	#4, sp

	; Display USP and SR (if requested)
	btst	#1, d6
	beq.s	@skip2

    ; Draw 'USP'
	lea		Str_USP(pc), a1
	lea		(sp), a2						; a2 = USP saved in stack (how convy!)
	jsr		Console_Write_Formatted(pc)

	; Draw 'SR'
	lea		Str_SR(pc), a1
	lea		(a4), a2
	jsr		Console_WriteLine_Formatted(pc)

@skip2:
	addq.w	#4, sp							; free USP copy from the stack (we don't need it anymore)

	jsr		Console_GetPosAsXY(pc)			; d0/d1 = XY-pos
	addq.w	#1, d1							; skip a line
	moveq	#1, d0							; left margin for data registers
	jsr		Console_SetPosAsXY(pc)


	; --------------------
	; Interrupt handlers
	; --------------------

	; Print vertical and horizontal interrupt handlers, if available
	move.l	$78.w, d0						; d0 = VInt vector address
	lea		Str_VInt(pc), a0
	jsr		Error_DrawInterruptHandler(pc)

	move.l	$70.w, d0						; d0 = HInt vector address
	lea		Str_HInt(pc), a0
	jsr		Error_DrawInterruptHandler(pc)

	jsr		Console_StartNewLine(pc)		; newline

	; -----------------
	; Stack contents
	; -----------------

	movea.l 0.w, a1							; a1 = stack top
	lea		(a4), a2						; a2 = stack bottom
	subq.l	#1, a1							; hotfix to convert stack pointer $0000 to $FFFF, decrement by 1 shouldn't make any difference otherwise
	bsr.s	Error_MaskStackBoundaries

	jsr		Console_GetPosAsXY(pc)			; d0/d1 = XY-pos
	moveq	#28-3, d5
	sub.w	d1, d5
	bmi.s	@stack_done

	bsr.s	Error_DrawStackRow_First

	@stack_loop:
		jsr		Error_DrawStackRow(pc)
		dbf		d5, @stack_loop

@stack_done:

	btst	#5, d6							; is execute console program (at the end) bit set?
	bne.s	Error_RunConsoleProgram

; -----------------------------------------------------------------------------
Error_IdleLoop:	__global
	nop
	bra.s	Error_IdleLoop

; -----------------------------------------------------------------------------
; Routine to enter console mode after writting error header
; -----------------------------------------------------------------------------

Error_EnterConsoleProgram:
	moveq	#0, d1
	jsr		Console_SetBasePattern(pc)

Error_RunConsoleProgram:
	move.l	a3, (sp)+						; replace USP in stack with return address
	movem.l	(sp)+, d0-a6					; restore registers
	pea		Error_IdleLoop(pc)				; set return address
	move.l	-$3C(sp), -(sp)					; retrieve "a3" saved earlier
	rts										; jump to a3

; -----------------------------------------------------------------------------
Error_InitConsole:	__global
	lea		ErrorHandler_ConsoleConfig(pc), a1
	lea		Art1bpp_Font(pc), a2
	jmp		Console_Init(pc)				; d5 = On-screen position


; =============================================================================
; -----------------------------------------------------------------------------
; Masks top and bottom stack boundaries to 24-bit
; -----------------------------------------------------------------------------
; INPUT:
;		a1		Stack top boundary
;		a2		Current stack pointer
;
; USES:
;		d1, d2
; -----------------------------------------------------------------------------

Error_MaskStackBoundaries:	__global
	move.l 	#$FFFFFF, d1

	move.l	a1, d2
	and.l	d1, d2
	move.l	d2, a1

	move.l	a2, d2
	and.l	d1, d2
	move.l	d2, a2
	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Subroutine to draw contents of stack row
; -----------------------------------------------------------------------------
; INPUT:
;		a0		String buffero
;		a1		Top of stack pointer
;		a2		Arguments (stack contents)
; -----------------------------------------------------------------------------

Error_DrawStackRow_First:
	lea		-$30(sp), sp
	lea		(sp), a0				; a0 = string buffer
	moveq	#-1, d7					; size of the buffer for formatter functions (we assume buffer will never overflow)

	move.l	#'(SP)', (a0)+
	move.w	#': ', (a0)+
	bra.s	Error_DrawStackRow_Continue

; -----------------------------------------------------------------------------
Error_DrawStackRow:
	lea		-$30(sp), sp
	lea		(sp), a0				; a0 = string buffer
	moveq	#-1, d7					; size of the buffer for formatter functions (we assume buffer will never overflow)

	move.w	#' +', (a0)+
	move.w	a2, d1
	sub.w	a4, d1					; d1 = stack displacement
	jsr 	FormatHex_Byte(pc)
	move.w	#': ', (a0)+

; -----------------------------------------------------------------------------
Error_DrawStackRow_Continue:
	moveq	#5, d0					; number of words to display

	@loop:
		moveq	#$FFFFFF00|_pal2, d1	; use light blue
		cmp.l	a1, a2					; is current word out of stack?
		blo.s	@0						; if not, branch
		moveq	#$FFFFFF00|_pal3, d1	; use dark blue
	@0:	move.b	d1, (a0)+				; setup color
		move.w	(a2)+, d1
		jsr		FormatHex_Word(pc)
		move.b	#' ', (a0)+
		dbf 	d0, @loop

	clr.b	(a0)+					; finalize string

	; Draw string on screen
	lea		(sp), a0
	moveq	#0, d1
	jsr		Console_WriteLine_WithPattern(pc)
	lea		$30(sp), sp
	rts

; =============================================================================
; -----------------------------------------------------------------------------
; Utility function to draw exception location
; -----------------------------------------------------------------------------
; INPUT:
;		d1	.l	Exception offset
;		a0		Label
; -----------------------------------------------------------------------------

Error_DrawOffsetLocation:	__global
	jsr		Console_Write(pc)				; display label
	; fallthrough

Error_DrawOffsetLocation2:	__global
	move.l	d1, -(sp)
	move.l	d1, -(sp)
	lea		(sp), a2						; a2 = arguments buffer

	; Non-linkable builds can override "Str_OffsetLocation_24bit"
	; using Blob2Asm (poor man's linker)
	if def(__LINKABLE__)=0
Error_DrawOffsetLocation__inj:	__global
	endif
	lea		Str_OffsetLocation_24bit(pc), a1

	jsr		Console_WriteLine_Formatted(pc)
	addq.w	#8,sp							; free arguments buffer
	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Subroutine to draw series of registers
; -----------------------------------------------------------------------------
; INPUT:
;		d0	.w	Name of the first register ('d0' or 'a0')
;		d5	.w	Number of registers
;		a2		Registers buffer
; -----------------------------------------------------------------------------

Error_DrawRegisters:
	lea		-$10(sp), sp				; allocate string buffaro
	moveq	#-1, d7						; size of the buffer for formatter functions (we assume buffer will never overflow)

	@regloop:
		lea		(sp), a0						; use allocated stack space as string buffer
		move.w	d0, (a0)+						; put register name
		move.w	#': ', (a0)+					; put ": "
		move.b	#_pal2, (a0)+					; put palette flag
		move.l	(a2)+, d1
		jsr		FormatHex_LongWord(pc)			; put register contents
		clr.b	(a0)+							; finalize string

		lea		(sp), a0						; use allocated stack space as string buffer
		moveq	#0, d1							; default pattern
		jsr		Console_WriteLine_WithPattern(pc)
		addq.w	#1, d0							; next register name
		dbf		d5, @regloop

	lea		$10(sp), sp

Error_Return:
	rts



; =============================================================================
; -----------------------------------------------------------------------------
; Subroutine to draw series of registers
; -----------------------------------------------------------------------------
; INPUT:
;		d0	.l	Interrupt handler address
;		a0		Handler name string
; -----------------------------------------------------------------------------

Error_DrawInterruptHandler:
	move.l	d0, d1
	swap	d1
	not.b	d1							; does handler address point to RAM (block $FF)?
	bne.s	Error_Return				; if not, branch

	movea.l	d0, a2						; a2 = handler routine
	cmp.w	#$4EF9, (a2)+				; does routine start jmp (xxx).l opcode?
	bne.s	@chk_jmp_xxx_w				; if not, branch
	move.l	(a2), d1					; d1 = interrupt handler offset
	bra.s	Error_DrawOffsetLocation

; ---------------------------------------------------------------
@chk_jmp_xxx_w:
	cmp.w	#$4EF8, -2(a2)				; does routine start with jmp (xxx).w opcode?
	bne.s	@uknown_handler_address		; if not, branch
	move.w	(a2), d1
	ext.l	d1							; d1 = interrupt handler offset
	bra.s	Error_DrawOffsetLocation

; ---------------------------------------------------------------
@uknown_handler_address:
	jsr		Console_Write(pc)
	lea		Str_Undefined(pc), a0
	jmp		Console_WriteLine(pc)


; =============================================================================
; -----------------------------------------------------------------------------
; Subroutine to guess caller by inspecting stack
; -----------------------------------------------------------------------------
; INPUT:
;		a1				Stack top boundary
;		a2				Stack bottom boundary (after stack frame)
;
; OUTPUT:
;		d1		.l		Caller offset or 0, if not found
;
; USES:
;		a1-a2
; -----------------------------------------------------------------------------

Error_GuessCaller:
	subq.l	#4, a1					; set a final longword to read
	jsr		Error_MaskStackBoundaries(pc)
	cmpa.l	a2, a1
	blo.s	@nocaller

@try_offset:
	cmp.w	#$40, (a2)				; does this seem like an offset?
	blo.s	@caller_found			; if yes, branch

@try_next_offset:
	addq.l	#2, a2					; try some next offsets
	cmpa.l	a2, a1
	bhs.s	@try_offset

@nocaller:
	moveq	#0, d1
	rts

; -----------------------------------------------------------------------------
@caller_found:
	move.l	(a2), d1
	beq.s	@try_next_offset		; if offset is zero, branch
	btst	#0, d1					; is this offset even?
	bne.s	@try_next_offset		; if not, branch
	rts


; =============================================================================
; -----------------------------------------------------------------------------
; Subroutine to setup/reset VDP in order to display properly
; -----------------------------------------------------------------------------

ErrorHandler_SetupVDP:	__global
	lea 	VDP_Ctrl, a5 			; a5 = VDP_Ctrl
	lea 	-4(a5), a6				; a6 = VDP_Data

	; Make sure there are no DMA's occurring, otherwise wait
	@wait_dma:
		move.w	(a5), ccr				; is DMA occurring? (also clears VDP write flag)
		bvs.s	@wait_dma				; wait until it's finished

	; Setup VDP registers for Error Handler screen
	lea 	ErrorHandler_VDPConfig(pc), a0

	@setup_regs:
		move.w	(a0)+, d0
		bpl.s	@done
		move.w	d0, (a5)
		bra.s	@setup_regs

	@done:

	; Remove all sprites, reset horizontal and vertical scrolling
	moveq	#0, d0
	vram	$0000, (a5)				; reset sprites and horizontal scrolling (HSRAM)
	move.l	d0, (a6)				; ''
	move.l	#$40000010, (a5) 		; reset vertical scrolling
	move.l	d0, (a6)				; ''

	; Fill screen with black
	cram	$00, (a5)
	move.w	d0, (a6)

	rts

; -----------------------------------------------------------------------------
; Error screen's VDP configuration
; -----------------------------------------------------------------------------

ErrorHandler_VDPConfig:	__global
	dc.w	$8004							; $00, disable HInts
	dc.w	$8134							; $01, disable DISP
	dc.w	$8500							; $05, set Sprites offset to $0000
	dc.w	$8700							; $07, set backdrop color
	dc.w	$8B00							; $0B, set VScroll=full, HScroll=full
	dc.w	$8C81							; $0C, use 320 pixels horizontal resolution
	dc.w	$8D3F							; $0D, set HScroll table offset to $FC00
	dc.w	$8F02							; $0F, set auto-increment to $02
	dc.w	$9011							; $10, use 512x512 plane resolution
	dc.w	$9100							; $11, reset Window X-position
	dc.w	$9200							; $12, reset Window Y-position
	; fallthrough

ErrorHandler_VDPConfig_Nametables:	__global
	dc.w	$8200+VRAM_ErrorScreen/$400		; $02, set Plane A nametable offset in VRAM
	dc.w	$8400+VRAM_ErrorScreen/$2000	; $04, set Plane B nametable offset in VRAM
	dc.w	0


; =============================================================================
; -----------------------------------------------------------------------------
; Console loading programme for Error Handler
; -----------------------------------------------------------------------------

ErrorHandler_ConsoleConfig:

	; -----------------------------------------------------------------------------
	; Font decompression programme
	; -----------------------------------------------------------------------------
	; NOTICE: It's possible to generate several "samples" of font
	;	with different color indecies at different VRAM locations.
	;	However, this is not used for this Error Handler
	; -----------------------------------------------------------------------------

	dcvram	VRAM_Font					; font offset in VRAM
	dc.w	$0000, $0001, $0010, $0011	; decompression table for 1bpp nibbles
	dc.w	$0100, $0101, $0110, $0111	; ''
	dc.w	$1000, $1001, $1010, $1011	; ''
	dc.w	$1100, $1101, $1110, $1111	; ''

	dc.w	-1							; end marker

	; -----------------------------------------------------------------------------
	; CRAM data
	; -----------------------------------------------------------------------------
	; FORMAT:
	;	dc.w	Color1, ..., ColorN, -X*2
	;		X = Number of longwords to fill until line ends
	;
	; NOTICE: Transparent color at the beginning of a palette line is
	;	auto-filled with $000 (black), hence Color1 is index #1, etc
	;
	; WARNING: Caution is required when calculating -X*2 as it's used
	;	for a jump offset directly in Console_Init code.
	;
	; WARNING: Make sure size of colors you pass (+automatic
	;	transparency color) and fill size sums to $20 bytes strictly!
	;	-- You can only fill with 4 bytes precision!
	;	-- Use dummy colors if neccessary.
	; -----------------------------------------------------------------------------

	dc.w	$0EEE, -7*2					; line 0: white text
	dc.w	$00CE, -7*2					; line 1: yellow text
	dc.w	$0EEA, -7*2					; line 2: lighter blue text
	dc.w	$0E86, -7*2					; line 3: darker blue text
	; fallthrough

	; -----------------------------------------------------------------------------
	; Console RAM initial config
	; -----------------------------------------------------------------------------

ErrorHandler_ConsoleConfig_Initial:	__global
	dcvram	VRAM_ErrorScreen			; screen start address / plane nametable pointer
	dcvram	VRAM_ErrorHScroll			; HSRAM address
	dc.w	VSRAM_ErrorVScroll			; VSRAM address

	dc.w	40							; number of characters per line
	dc.w	40							; number of characters on the first line (meant to be the same as the above)
	dc.w	0							; base font pattern (tile id for ASCII $00 + palette flags)
	dc.w	$80							; size of screen row (in bytes)

	dc.w	$2000/$20-1					; size of screen (in tiles - 1)


; -----------------------------------------------------------------------------
; Error Handler interface data
; -----------------------------------------------------------------------------

Str_SetErrorScreen:
	dc.b	_pal1, _newl, _setx, 1, _setw, 38, 0

Str_Address:
	dc.b	_pal1, 'Address: ', 0

Str_Offset:
	dc.b	_pal1, 'Offset: ', 0

Str_Caller:
 	dc.b	_pal1, 'Caller: ', 0

Str_OffsetLocation_24bit:	__global
	dc.b	_pal2, _hex|byte, _hex|word, ' ', _pal0, _sym|long|split|forced, _pal2, _disp|weak, 0

Str_OffsetLocation_32bit:	__global
	dc.b	_pal2, _hex|long, ' ', _pal0, _sym|long|split|forced, _pal2, _disp|weak, 0

Str_USP:
	dc.b	_setx, $10, _pal0, 'usp: ', _pal2, _hex|long, 0

Str_SR:
	dc.b	_setx, $03, _pal0, 'sr: ', _pal2, _hex|word, 0

Str_VInt:
	dc.b	_pal1, 'VInt: ', 0

Str_HInt:
	dc.b	_pal1, 'HInt: ', 0

Str_Undefined:
	dc.b	_pal0, '<undefined>', 0
	even
