	if def(_MACRO_DEFS)=0
_MACRO_DEFS:	equ	1

; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; Macros definitions file
; ---------------------------------------------------------------

VDP_Data		equ 	$C00000
VDP_Ctrl		equ 	$C00004

; Generate VRAM write command
vram	macro	offset,operand
		if (narg=1)
				move.l	#($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14)),VDP_Ctrl
		else
				move.l	#($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14)),\operand
		endc
		endm

; Generate dc.l constant with VRAM write command
dcvram	macro	offset
		dc.l	($40000000+(((\offset)&$3FFF)<<16)+(((\offset)&$C000)>>14))
		endm


; Generate CRAM write command
cram	macro	offset,operand
		if (narg=1)
				move.l	#($C0000000+((\offset)<<16)),VDP_Ctrl
		else
				move.l	#($C0000000+((\offset)<<16)),\operand
		endc
		endm
		
; A special macro to define externally visible symbols
__global macro	*
		; For linkable builds, use `xdef` to export symbol
		if def(__LINKABLE__)
		xdef	MDDBG__\*
		endc

MDDBG__\*:	; full global symbol name uses "MD Debugger" prefix to minimize naming conflicts

\*:	; place the original symbol itself
		endm

	endc	; _MACRO_DEFS
