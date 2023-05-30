
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Full exception test
; ---------------------------------------------------------------

VInt_Address:	equ		$FFFFC000
HInt_Address:	equ		$00FFC006

RAM_Interrupts:	equ		VInt_Address

Vectors:
	dc.l	$FFFFF0,		EntryPoint,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	HInt_Address,	ErrorTrap,		VInt_Address,	ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap
	dc.l	ErrorTrap,		ErrorTrap,		ErrorTrap,		ErrorTrap

; ---------------------------------------------------------------
ROMHeader:
	dc.b	'SEGA MEGA DRIVE ' 										; Hardware system ID
	dc.b	'(C)VLAD 2023.MAY'										; Release date
	dc.b	'SEGA MEGA DRIVE APPLICATION                     '		; Domestic name
	dc.b	'SEGA MEGA DRIVE APPLICATION                     '		; International name
	dc.b	'GM xxxxxxxx-xx'										; Serial/version number
	dc.w	0														; Checksum
	dc.b	'J               '										; I/O support
	dc.l	$000000, $0FFFFF										; ROM range
	dc.l	$FF0000, $FFFFFF										; RAM range
	dc.b	'            '											; Back-up RAM data
	dc.b	'                                                    '	; Notes
	dc.b	'JUE             ' 										; Supported regions

; ---------------------------------------------------------------
ErrorTrap:
	nop
	bra.s	ErrorTrap

; ---------------------------------------------------------------
; Entry Point : Initializes hardware
; ---------------------------------------------------------------

EntryPoint:
	move	#$2700, sr					; disable interrupts, reset CCR
	lea		@SetupValues(pc), a0
	movem.l	(a0)+, a2-a5				; init address registers

	tst.w	$A1000C-$A11100(a3)			; is Port C ready?
	bne.s	@Init_Done					; if yes, branch

	movem.w	(a0)+, d0-d6				; init data registers

	; ---------------------
	; Pass hardware check
	; ---------------------

	moveq	#$F, d7
	and.b	$A10001-$A11100(a3), d7		; get hardware revision
	beq.s	@HW_Done					; for older revisions, skip the following code ...
	move.l	$100.w, $A14000-$A11100(a3)	; write word 'SEGA' to the hardware port to enable VDP
@HW_Done:

	; ------------------------------------------------------------------------
	; Request Z80 stop in order to load Z80 programme later
	; (the "Setup VDP" block should create enough delay for Z80 to release bus)
	; ------------------------------------------------------------------------

	move.w	d1, (a3)				; Z80 => Request bus
	move.w	d1, (a4)				; Z80 => Request reset

	; ---------------------------
	; Setup VDP: Main registers
	; ---------------------------

	tst.w	(a2)					; VDP => clear 'write pending' bit

	@VDP_SetupRegisters:
		move.w	d2, (a2)			; VDP => Send register
		add.w	d1, d2				; increment to next register
		move.b	(a0)+, d2			; load next register value
		dbf		d3, @VDP_SetupRegisters

	; --------------------
	; Load Z80 programme
	; --------------------

	move.b	d2, (a5)+				; Z80 => Write 'di' opcode
	move.b	(a0)+, (a5)+			; Z80 => Write 'jp' opcode

	@Z80_ClearRAM:
		move.b	d0, (a5)+
		dbf		d5, @Z80_ClearRAM

	move.w	d0, (a4)			; Z80 => Release reset
	move.w	d0, (a3)			; Z80 => Release bus
	move.w	d1, (a4)			; Z80 => Request reset

	; ------------------------------------
	; Setup VDP: Clear VRAM, CRAM, VSRAM
	; ------------------------------------

	@VDP_ClearRAM:
		move.l	(a0)+, (a2)			; VDP => setup access request
		move.w	(a0)+, d7			; d7 = Number of longwords to clear, minus one
		@0:	move.l	d0, -4(a2)       		; VDP => Fill with zeroes
			dbf		d7, @0
		dbf		d4, @VDP_ClearRAM


	; ----------
	; Clear RAM
	; ----------

	suba.l	a6, a6				; a6 = $000000
	
	@RAM_Clear:
		move.l	d0, -(a6)
		dbf		d6, @RAM_Clear

	; ----------
	; Setup PSG
	; ----------
	
	@PSG_Loop:
		move.b	d4, $11(a1)			; PSG => Silence channel
		sub.b	#$20, d4			; iterate through values $FF, $DF, $BF, $9F
		bmi.s	@PSG_Loop			; loop

	move.w	d0, (a4)			; Z80 => Release reset

@Init_Done:
	bra.s	ProgramStart

; ---------------------------------------------------------------
@SetupValues:
	dc.l	$C00004			; a2 = VDP Control Port
	dc.l	$A11100			; a3 = Z80 bus request
	dc.l	$A11200			; a4 = Z80 reset
	dc.l	$A00000			; a5 = Z80 RAM

	dc.w	$0000			; d0 = Zero value / Z80 request OFF command
	dc.w	$0100			; d1 = VDP register increment value / Z80 request ON command
	dc.w	$8004			; d2 = VDP initial setup value (from which the iteration starts)
	dc.w	$0012			; d3 = Loop count: Size of VDP setup list in bytes, minus one
	dc.w	$0002			; d4 = Loop count: Number of VDP clear programmes, minus one
	dc.w	$1FFD			; d5 = Loop count: Number of bytes to clear in Z80 RAM, minus one
	dc.w	$3FFF			; d6 = Loop count: Number of longwords to clear in 68K RAM, minus one

	; VDP Setup values
						; register $00 : Enable HInt, enable HV-counter (see above)
	dc.b	$14			; register $01 : Enable VInt, enable DMA, disable display
	dc.b	$30			; register $02 : Set Plane A nametable address
	dc.b	$3C			; register $03 : Set Window Plane address
	dc.b	$07			; register $04 : Set Plane B nametable address
	dc.b	$6C			; register $05 : Set sprite table address
	dc.b	$00			; register $06 :
	dc.b	$00			; register $07 : Set backdrop color
	dc.b	$00			; register $08 :
	dc.b	$00			; register $09 :
	dc.b	$FF			; register $0A : Horizontal interrupt counter
	dc.b	$00			; register $0B : Setup Vertical and Horizontal scrolling modes
	dc.b	$81			; register $0C : Setup S&H, horizontal cell mode and interlancing
	dc.b	$37			; register $0D : Setup HSRAM address
	dc.b	$00			; register $0E :
	dc.b	$02			; register $0F : Setup auto-increment value
	dc.b	$01			; register $10 : Setup plane sizes
	dc.b	$00			; register $11 : Setup Window X-position
	dc.b	$00			; register $12 : Setup Window Y-position

	; Z80 Idle programme
	dc.b	$F3			; 0000h :	di
	dc.b	$C3;, $00, $00		; 0001h :	jp	0000h		; NOTE: zeroes are appended as part of RAM clearing programme

	; VDP clear programmes (access command, length in longwords)
	dc.l	$40000000		; VRAM access request
	dc.w	$3FFF			; VRAM length in longwords, minus one
	dc.l	$C0000000		; CRAM access request
	dc.w	$1F				; CRAM length in longwords, minus one
	dc.l	$40000010		; VSRAM access request
	dc.w	$13				; VSRAM length in longwords, minus one

; ---------------------------------------------------------------
; Statup code
; ---------------------------------------------------------------

ProgramStart:
	movea.l	0.w, sp

	; Init joypad ports
	moveq	#$40,d0
	move.b	d0, $A10009	; init port 1 (joypad 1)
	move.b	d0, $A1000B	; init port 2 (joypad 2)
	move.b	d0, $A1000D	; init port 3 (extra)

	lea		RAM_Interrupts, a0
	lea		VInt_Data(pc), a1
	move.l	(a1)+, (a0)+
	move.l	(a1)+, (a0)+
	move.l	(a1)+, (a0)+
	; fallthrough

; ---------------------------------------------------------------
; Main programme
; ---------------------------------------------------------------

Main:
	movem.l	FakeRegData, d0-a6

	jsr		FakeException
	; [[unreachable]]
	bra		ErrorTrap

; ---------------------------------------------------------------
FakeException:
	move.w	sr, -(sp)

	; Extended stack frame (8 bytes)
	move.w	#$5678, -(sp)
	move.l	#FakeAddressErrorLocation, -(sp)
	move.w	#$1234, -(sp)

	jsr		ErrorHandler
	dc.b	"FAKE ADDRESS ERROR", 0
	dc.b	%00000011
	rte

; ---------------------------------------------------------------
VInt_Data:
	jmp		(Dummy_VInt).l

HInt_Data:
	jmp		(Dummy_HInt).l

; ---------------------------------------------------------------
Dummy_VInt:
	rte

Dummy_HInt:
	rte

; ---------------------------------------------------------------
FakeRegData:
	dc.l	$00000000		; d0
	dc.l	$00010001		; d1
	dc.l	$00020002		; d2
	dc.l	$00030003		; d3
	dc.l	$00040004		; d4
	dc.l	$00050005		; d5
	dc.l	$00060006		; d6
	dc.l	$00070007		; d7
	dc.l	$00000000		; a0
	dc.l	$00010000		; a1
	dc.l	$00020000		; a2
	dc.l	$00030000		; a3
	dc.l	$00040000		; a4
	dc.l	$00050000		; a5
	dc.l	$00060000		; a6

; ---------------------------------------------------------------
FakeAddressErrorLocation:
	nop

; ---------------------------------------------------------------

	include	"ErrorHandler.asm"
