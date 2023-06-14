
; ===============================================================
; ---------------------------------------------------------------
; Subroutine to generate 1bpp decode table
; ---------------------------------------------------------------
; INPUT:
;		a1		Address for the generated table
;		d4	.w	Pixel index for bit #0
;		d5	.w	Pixel index for bit #1
;
; USES:
;		a0-a2
; ---------------------------------------------------------------

Generate1bppDecodeTable:
	lea		(a1), a0
	move.w	d5, d6
	beq.s	@Pixel1Indexes_Zero   
	lsl.w	#4, d6
	lea		@BaseIndexTable-$10(pc,d6), a2
	moveq	#8-1, d6						; repeat counter

@Fill_Pixel1Indexes:
	move.w	(a2)+, d0
	move.w	d0, (a0)+
	or.w	d5, d0
	move.w	d0, (a0)+
	dbf		d6, @Fill_Pixel1Indexes

	lea		(a1), a0
@Generate_Pixel0Indexes:
	move.w	d4, d6
	beq.s	@Pixel0Indexes_Zero
	lsl.w	#4, d6
	lea		@BaseIndexTable(pc,d6), a2
	moveq	#8-1, d6						; repeat counter

@Fill_Pixel0Indexes:
	move.w	-(a2), d0
	move.w	d0, d1
	or.w	d4, d1
	add.w	d1, (a0)+
	add.w	d0, (a0)+
	dbf		d6, @Fill_Pixel0Indexes
	rts

; ---------------------------------------------------------------
@Pixel1Indexes_Zero:
	moveq	#0, d0
	moveq	#0, d1
	moveq	#0, d2
	moveq	#0, d3
	movem.l	d0-d3, (a0)
	movem.l	d0-d3, $10(a0)
	bra.s	@Generate_Pixel0Indexes

; ---------------------------------------------------------------
@Pixel0Indexes_Zero:
	rts
                        
; ---------------------------------------------------------------
@BaseIndexTable:
	dc.w	$0000, $0010, $0100, $0110, $1000, $1010, $1100, $1110
	dc.w	$0000, $0020, $0200, $0220, $2000, $2020, $2200, $2220
	dc.w	$0000, $0030, $0300, $0330, $3000, $3030, $3300, $3330
	dc.w	$0000, $0040, $0400, $0440, $4000, $4040, $4400, $4440
	dc.w	$0000, $0050, $0500, $0550, $5000, $5050, $5500, $5550
	dc.w	$0000, $0060, $0600, $0660, $6000, $6060, $6600, $6660
	dc.w	$0000, $0070, $0700, $0770, $7000, $7070, $7700, $7770
	dc.w	$0000, $0080, $0800, $0880, $8000, $8080, $8800, $8880
	dc.w	$0000, $0090, $0900, $0990, $9000, $9090, $9900, $9990
	dc.w	$0000, $00A0, $0A00, $0AA0, $A000, $A0A0, $AA00, $AAA0
	dc.w	$0000, $00B0, $0B00, $0BB0, $B000, $B0B0, $BB00, $BBB0
	dc.w	$0000, $00C0, $0C00, $0CC0, $C000, $C0C0, $CC00, $CCC0
	dc.w	$0000, $00D0, $0D00, $0DD0, $D000, $D0D0, $DD00, $DDD0
	dc.w	$0000, $00E0, $0E00, $0EE0, $E000, $E0E0, $EE00, $EEE0
	dc.w	$0000, $00F0, $0F00, $0FF0, $F000, $F0F0, $FF00, $FFF0

