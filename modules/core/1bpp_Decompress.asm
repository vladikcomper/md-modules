
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Fast 1bpp decompressor
; ---------------------------------------------------------------
; INPUT:
;		a0		Source 1bpp art
;		a1		Decode table (generated or manual)
;		d4	.w	Size of art in bytes - 1
;		a6		VDP Data Port
;
; USES:
;		a0, d0-d2/d4
; ---------------------------------------------------------------

Decomp1bpp:	__global
	moveq	#$1E, d2

	@row:
		move.b	(a0)+, d0				; d0 = %aaaa bbbb
		move.b	d0, d1
		lsr.b	#3, d1					; d1 = %000a aaab
		and.w	d2, d1					; d1 = %000a aaa0
		move.w	(a1,d1), (a6)			; decompress first nibble
	
		add.b	d0, d0					; d0 = %aaab bbb0
		and.w	d2, d0					; d0 = %000b bbb0
		move.w	(a1,d0), (a6)			; decompress second nibble
		
		dbf		d4, @row

	rts
