#include cbundle_disclaimer

; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Debugger testing module : Flow tester
; ---------------------------------------------------------------
; NOTICE:
;	This unit tests whether using debugger macros in instruction
;	flow affects program execution, which they shouldn't.
;	The check is performed on processor registers state, which
;	should be influenced by calling internal debugger routines.
;
; WARNING:
; 	This testing unit is designed to work with both ASM68k and AS
;	assemblers, however, a few changes are forced on syntax of
;	certain calls due to AS limitations.
; ---------------------------------------------------------------

#ifdef ASM68K
	include	"..\bundle-asm68k\MDShell.asm"
#else
	include "..\bundle-as\MDShell.asm"
#endif

; --------------------------------------------------------------

Main:
	; Initialize registers with pseudo-random values,
	; found at "RegisterData" byte-array (see below)
	movem.l	RegisterData, d0-a6

; --------------------------------------------------------------
Test_BasicString:
	; Using Console.Write with Console with plain string ...
	Console.Write "Starting flow tests within console program..."
	jsr		CheckRegisterIntergity

; --------------------------------------------------------------
Test_LineBreak:
	; Using Console.BreakLine ...
	Console.BreakLine
	jsr		CheckRegisterIntergity

; --------------------------------------------------------------
Test_BasicFlags:
	; Using Console.Write with basic control flags ...
	Console.Write "Flags: %<pal0>CO%<pal1>LO%<pal2>RS%<pal3>!~%<endl>"
	jsr		CheckRegisterIntergity

; --------------------------------------------------------------
Test_ExtendedFlags:
	; Using "setx" and "setw" flags with test output ...
#ifdef ASM68K
	Console.Write "%<setx,1,setw,20>"
#else
##	; AS assembler implementation has limitations on formatting capabilities
	Console.Write "%<setx>%<1>%<setw>%<20>"
#endif
	Console.Write "Testing paragraph fill with 'setx' and 'setw' flags...%<pal0>"
#ifdef ASM68K
	Console.Write "%<endl,setx,0,setw,40>"
#else
##	; AS assembler implementation has limitations on formatting capabilities
	Console.Write "%<endl>%<setx>%<0>%<setw>%<40>"
#endif
	jsr		CheckRegisterIntergity

; --------------------------------------------------------------
Test_Formatters:
	; Using Console.Write to display formatted values ...
	Console.Write "Testing formatters ...%<endl>"
	jsr		CheckRegisterIntergity

Test_Formatter_Default:
	Console.Write "%<pal1>Default: %<pal0>"
	Console.Write "%<.b d0>-%<.w d0>-%<.l d0>%<endl>"
	jsr		CheckRegisterIntergity
Test_Formatter_HEX:
	Console.Write "%<pal1>hex: %<pal0>"
	Console.Write "%<.b d0 hex>-%<.w d0 hex>-%<.l d0 hex>%<endl>"
	jsr		CheckRegisterIntergity    

Test_Formatter_DEC:
	Console.Write "%<pal1>dec: %<pal0>"
	Console.Write "%<.b d0 dec>-%<.w d0 dec>-%<.l d0 dec>%<endl>"
	jsr		CheckRegisterIntergity

Test_Formatter_SYM:
	Console.Write "%<pal1>sym: %<pal0>"
	Console.Write "%<.b d0 sym>-%<.w d0 sym>-%<.l d0 sym>%<endl>"
	jsr		CheckRegisterIntergity

Test_Formatter_SYM_SPLIT:
	Console.Write "%<pal1>sym|split: %<pal0>"
	Console.Write "%<.b d0 sym|split>%<pal2>%<symdisp>%<pal0>-"
	Console.Write "%<.w d0 sym|split>%<pal2>%<symdisp>%<pal0>-"
	Console.Write "%<.l d0 sym|split>%<pal2>%<symdisp>%<pal0>"
	jsr		CheckRegisterIntergity

; --------------------------------------------------------------
Test_MiscCommands:
	; Using misc. commands related to Console enitity ...
	Console.SetXY #3, #20
	Console.Write "Positioning test #1 ..."
	Console.BreakLine
	Console.Write "Positioning test #2 ..."
	jsr		CheckRegisterIntergity

	rts

; ==============================================================
; --------------------------------------------------------------
; Subroutine that check if current register values match
; array they were initialized with ...
; --------------------------------------------------------------

CheckRegisterIntergity:
	movem.l	d0-a6, -(sp)

	lea		(sp), a0				; a0 = registers dump pointer
	lea		RegisterData, a1		; a1 = source registers pointer
	moveq	#15-1, d0				; d0 = number of registers minus 1

__loop:
	cmpm.l	(a0)+, (a1)+
	dbne	d0, __loop
	bne.s	__corrupted
	movem.l	(sp)+, d0-a6
	rts

; --------------------------------------------------------------
__corrupted:
	subq.w	#4, a0
	subq.w	#4, a1
	lea		RegisterNames-RegisterData(a1), a2
	lea		$3C(sp), a3

#ifdef ASM68K
	Console.Write "%<endl,pal1>@%<.l (a3) sym|split>: %<endl,pal0> Register %<pal1>%<.l a2 hex>%<pal0> corrupted!%<endl> Got %<pal2>%<.l (a0)>%<pal0>, expected %<pal2>%<.l (a1)>%<pal0,endl>"
#else
##	; AS assembler implementation has limitations on formatting capabilities
##	; Moreover, AS is incapable of parsing stings that include more than 160 characters
	Console.Write "%<endl>%<pal1>@%<.l (a3) sym|split>: %<endl>%<pal0> Register %<pal1>%<.l a2 hex>%<pal0> corrupted!"
	Console.Write "%<endl> Got %<pal2>%<.l (a0)>%<pal0>, expected %<pal2>%<.l (a1)>%<pal0>%<endl>"
#endif
	bra	*

; --------------------------------------------------------------
RegisterData:
	dc.b $47, $2F, $74, $1E, $5B, $57, $06, $22, $38, $3D, $52, $9E, $AF, $4F
	dc.b $BD, $96, $F0, $8A, $3B, $BB, $B9, $E2, $96, $B0, $6E, $26, $FB, $C1
	dc.b $6D, $21, $D0, $06, $41, $04, $0E, $FD, $93, $72, $92, $32, $E0, $AB
	dc.b $2F, $77, $70, $A8, $76, $B6, $0F, $3C, $6D, $7C, $70, $72, $B5, $AA
	dc.b $5A, $CB, $DC, $F9

RegisterNames:
	dc.w 'd0',0,'d1',0,'d2',0,'d3',0,'d4',0,'d5',0,'d6',0,'d7',0
	dc.w 'a0',0,'a1',0,'a2',0,'a3',0,'a4',0,'a5',0,'a6',0
