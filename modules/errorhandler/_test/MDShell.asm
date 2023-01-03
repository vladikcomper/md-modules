
; ===============================================================
; ---------------------------------------------------------------
; MD Shell 2.0
; 2023, Vladikcomper
; ---------------------------------------------------------------


; ===============================================================
; ---------------------------------------------------------------
; Constants
; ---------------------------------------------------------------

; ----------------------------
; Arguments formatting flags
; ----------------------------

; General arguments format flags
hex		equ		$80				; flag to display as hexadecimal number
dec		equ		$90				; flag to display as decimal number
bin		equ		$A0				; flag to display as binary number
sym		equ		$B0				; flag to display as symbol (treat as offset, decode into symbol +displacement, if present)
symdisp	equ		$C0				; flag to display as symbol's displacement alone (DO NOT USE, unless complex formatting is required, see notes below)
str		equ		$D0				; flag to display as string (treat as offset, insert string from that offset)

; NOTES:
;	* By default, the "sym" flag displays both symbol and displacement (e.g.: "Map_Sonic+$2E")
;		In case, you need a different formatting for the displacement part (different text color and such),
;		use "sym|split", so the displacement won't be displayed until symdisp is met
;	* The "symdisp" can only be used after the "sym|split" instance, which decodes offset, otherwise, it'll
;		display a garbage offset.
;	* No other argument format flags (hex, dec, bin, str) are allowed between "sym|split" and "symdisp",
;		otherwise, the "symdisp" results are undefined.
;	* When using "str" flag, the argument should point to string offset that will be inserted.
;		Arguments format flags CAN NOT be used in the string (as no arguments are meant to be here),
;		only console control flags (see below).


; Additional flags ...
; ... for number formatters (hex, dec, bin)
signed	equ		8				; treat number as signed (display + or - before the number depending on sign)

; ... for symbol formatter (sym)
split	equ		8				; DO NOT write displacement (if present), skip and wait for "symdisp" flag to write it later (optional)
forced	equ		4				; display "<unknown>" if symbol was not found, otherwise, plain offset is displayed by the displacement formatter

; ... for symbol displacement formatter (symdisp)
weak	equ		8				; DO NOT write plain offset if symbol is displayed as "<unknown>"

; Argument type flags:
; - DO NOT USE in formatted strings processed by macros, as these are included automatically
; - ONLY USE when writting down strings manually with DC.B
byte	equ		0
word	equ		1
long	equ		3

; -----------------------
; Console control flags
; -----------------------

; Plain control flags: no arguments following
endl	equ		$E0				; "End of line": flag for line break
cr		equ		$E6				; "Carriage return": jump to the beginning of the line
pal0	equ		$E8				; use palette line #0
pal1	equ		$EA				; use palette line #1
pal2	equ		$EC				; use palette line #2
pal3	equ		$EE				; use palette line #3

; Parametrized control flags: followed by 1-byte argument
setw	equ		$F0				; set line width: number of characters before automatic line break
setoff	equ		$F4				; set tile offset: lower byte of base pattern, which points to tile index of ASCII character 00
setpat	equ		$F8				; set tile pattern: high byte of base pattern, which determines palette flags and $100-tile section id
setx	equ		$FA				; set x-position


; ---------------------------------------------------------------
; Import global functions
; ---------------------------------------------------------------

ErrorHandler.__global__error_initconsole equ $552
ErrorHandler.__global__errorhandler_setupvdp equ $656
ErrorHandler.__global__art1bpp_font equ $754
ErrorHandler.__global__formatstring equ $D1C
ErrorHandler.__global__console_loadpalette equ $E36
ErrorHandler.__global__console_setposasxy_stack equ $E72
ErrorHandler.__global__console_setposasxy equ $E78
ErrorHandler.__global__console_getposasxy equ $EA4
ErrorHandler.__global__console_startnewline equ $EC6
ErrorHandler.__global__console_setbasepattern equ $EEE
ErrorHandler.__global__console_setwidth equ $F02
ErrorHandler.__global__console_writeline_withpattern equ $F18
ErrorHandler.__global__console_writeline equ $F1A
ErrorHandler.__global__console_write equ $F1E
ErrorHandler.__global__console_writeline_formatted equ $FCA
ErrorHandler.__global__console_write_formatted equ $FCE
ErrorHandler.__global__decomp1bpp equ $FFE

; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

RaiseError &
	macro	string, console_program, opts

	pea		*(pc)
	move.w	sr, -(sp)
	__FSTRING_GenerateArgumentsCode \string
	jsr		ErrorHandler
	__FSTRING_GenerateDecodedString \string
	if strlen("\console_program")			; if console program offset is specified ...
		dc.b	\opts+_eh_enter_console|(((*&1)^1)*_eh_align_offset)	; add flag "_eh_align_offset" if the next byte is at odd offset ...
		even															; ... to tell Error handler to skip this byte, so it'll jump to ...
		jmp		\console_program										; ... an aligned "jmp" instruction that calls console program itself
	else
		dc.b	\opts+0						; otherwise, just specify \opts for error handler, +0 will generate dc.b 0 ...
		even								; ... in case \opts argument is empty or skipped
	endc
	even

	endm

; ---------------------------------------------------------------
Console &
	macro

	if strcmp("\0","write")|strcmp("\0","writeline")
		move.w	sr, -(sp)
		__FSTRING_GenerateArgumentsCode \1
		movem.l	a0-a2/d7, -(sp)
		if (__sp>0)
			lea		4*4(sp), a2
		endc
		lea		@str\@(pc), a1
		jsr		ErrorHandler.__global__console_\0\_formatted
		movem.l	(sp)+, a0-a2/d7
		if (__sp>8)
			lea		__sp(sp), sp
		elseif (__sp>0)
			addq.w	#__sp, sp
		endc
		move.w	(sp)+, sr
		bra.w	@instr_end\@
	@str\@:
		__FSTRING_GenerateDecodedString \1
		even
	@instr_end\@:

	elseif strcmp("\0","run")
		jsr		ErrorHandler.__extern__console_only
		jsr		\1
		bra.s	*

	elseif strcmp("\0","setxy")
		move.w	sr, -(sp)
		movem.l	d0-d1, -(sp)
		move.w	\2, -(sp)
		move.w	\1, -(sp)
		jsr		ErrorHandler.__global__console_setposasxy_stack
		addq.w	#4, sp
		movem.l	(sp)+, d0-d1
		move.w	(sp)+, sr

	elseif strcmp("\0","breakline")
		move.w	sr, -(sp)
		jsr		ErrorHandler.__global__console_startnewline
		move.w	(sp)+, sr

	else
		inform	2,"""\0"" isn't a member of ""Console"""

	endc
	endm

; ---------------------------------------------------------------
__ErrorMessage &
	macro	string, opts
		__FSTRING_GenerateArgumentsCode \string
		jsr		ErrorHandler
		__FSTRING_GenerateDecodedString \string
		dc.b	\opts+0
		even

	endm

; ---------------------------------------------------------------
__FSTRING_GenerateArgumentsCode &
	macro	string

	__pos:	set 	instr(\string,'%<')		; token position
	__stack:set		0						; size of actual stack
	__sp:	set		0						; stack displacement

	; Parse string itself
	while (__pos)

		; Retrive expression in brackets following % char
    	__endpos:	set		instr(__pos+1,\string,'>')
    	__midpos:	set		instr(__pos+5,\string,' ')
    	if (__midpos<1)|(__midpos>__endpos)
			__midpos: = __endpos
    	endc
		__substr:	substr	__pos+1+1,__endpos-1,\string			; .type ea param
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %(.w d0 hex) )
		if "\__type">>8="."
			__operand:	substr	__pos+1+1,__midpos-1,\string			; .type ea
			__param:	substr	__midpos+1,__endpos-1,\string			; param

			if "\__type"=".b"
				pushp	"move\__operand\,1(sp)"
				pushp	"subq.w	#2, sp"
				__stack: = __stack+2
				__sp: = __sp+2

			elseif "\__type"=".w"
				pushp	"move\__operand\,-(sp)"
				__stack: = __stack+1
				__sp: = __sp+2

			elseif "\__type"=".l"
				pushp	"move\__operand\,-(sp)"
				__stack: = __stack+1
				__sp: = __sp+4

			else
				fatal 'Unrecognized type in string operand: %<\__substr>'
			endc
		endc

		__pos:	set		instr(__pos+1,\string,'%<')
	endw

	; Generate stack code
	rept __stack
		popp	__command
		\__command
	endr

	endm

; ---------------------------------------------------------------
__FSTRING_GenerateDecodedString &
	macro string

	__lpos:	set		1						; start position
	__pos:	set 	instr(\string,'%<')		; token position

	while (__pos)

		; Write part of string before % token
		__substr:	substr	__lpos,__pos-1,\string
		dc.b	"\__substr"

		; Retrive expression in brakets following % char
    	__endpos:	set		instr(__pos+1,\string,'>')
    	__midpos:	set		instr(__pos+5,\string,' ')
    	if (__midpos<1)|(__midpos>__endpos)
			__midpos: = __endpos
    	endc
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %<.w d0 hex> )
		if "\__type">>8="."    
			__param:	substr	__midpos+1,__endpos-1,\string			; param
			
			; Validate format setting ("param")
			if strlen("\__param")<1
				__param: substr ,,"hex"			; if param is ommited, set it to "hex"
			elseif strcmp("\__param","signed")
				__param: substr ,,"hex+signed"	; if param is "signed", correct it to "hex+signed"
			endc

			if (\__param < $80)
				inform	2,"Illegal operand format setting: ""\__param\"". Expected ""hex"", ""dec"", ""bin"", ""sym"", ""str"" or their derivatives."
			endc

			if "\__type"=".b"
				dc.b	\__param
			elseif "\__type"=".w"
				dc.b	\__param|1
			else
				dc.b	\__param|3
			endc

		; Expression is an inline constant (e.g. %<endl> )
		else
			__substr:	substr	__pos+1+1,__endpos-1,\string
			dc.b	\__substr
		endc

		__lpos:	set		__endpos+1
		__pos:	set		instr(__pos+1,\string,'%<')
	endw

	; Write part of string before the end
	__substr:	substr	__lpos,,\string
	dc.b	"\__substr"
	dc.b	0

	endm


; ---------------------------------------------------------------
; MD-Shell blob
; ---------------------------------------------------------------

MDShell:

	dc.l	$00FFFFF0, $00000204, $00000302, $00000314, $0000032A, $00000346, $0000035A, $00000372
	dc.l	$0000038C, $000003A8, $000003B6, $000003D0, $000003EA, $000003EA, $000003EA, $000003EA
	dc.l	$000003EA, $000003EA, $000003EA, $000003EA, $000003EA, $000003EA, $000003EA, $000003EA
	dc.l	$000003EA, $000002FC, $000002FC, $000002FC, $00000300, $000002FC, $00000300, $000002FC
	dc.l	$000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC
	dc.l	$000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC
	dc.l	$000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC
	dc.l	$000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC, $000002FC
	dc.l	$53454741, $204D4547, $41204452, $49564520, $28432956, $4C414420, $32303233, $2E4A414E
	dc.l	$53454741, $204D4547, $41204452, $49564520, $4150504C, $49434154, $494F4E20, $20202020
	dc.l	$20202020, $20202020, $20202020, $20202020, $53454741, $204D4547, $41204452, $49564520
	dc.l	$4150504C, $49434154, $494F4E20, $20202020, $20202020, $20202020, $20202020, $20202020
	dc.l	$474D2078, $78787878, $7878782D, $78780000, $4A202020, $20202020, $20202020, $20202020
	dc.l	$00000000, $000FFFFF, $00FF0000, $00FFFFFF, $20202020, $20202020, $20202020, $20202020
	dc.l	$20202020, $20202020, $20202020, $20202020, $20202020, $20202020, $20202020, $20202020
	dc.l	$20202020, $20202020, $20202020, $20202020, $4A554520, $20202020, $20202020, $20202020
	dc.l	$00000000, $46FC2700, $41FA0064, $4CD83C00, $4A6BEF0C, $66564C98, $007F7E0F, $CE2BEF01
	dc.l	$67062778, $01002F00, $36813881, $4A523482, $D4411418, $51CBFFF8, $1AC21AD8, $1AC051CD
	dc.l	$FFFC3880, $36803881, $24983E18, $2540FFFC, $51CFFFFA, $51CCFFF2, $9DCE2D00, $51CEFFFC
	dc.l	$13440011, $04040020, $6BF63880, $604400C0, $000400A1, $110000A1, $120000A0, $00000000
	dc.l	$01008004, $00120002, $1FFD3FFF, $14303C07, $6C000000, $00FF0081, $37000201, $0000F3C3
	dc.l	$40000000, $3FFFC000, $0000001F, $40000010, $00137040, $13C000A1, $000913C0, $00A1000B
	dc.l	$13C000A1, $000D46FC, $27004FEF, $FFF247D7, $4EBA0384, $4EBA027C, $70007200, $74007600
	dc.l	$78007A00, $7C007E00, $20402241, $24422643, $28442A45, $2C464EB9, Main, $4E7160FC
	dc.l	$4E734EB9, $00000402, $42555320, $4552524F, $52000100, $4EB90000, $04024144, $44524553
	dc.l	$53204552, $524F5200, $01004EB9, $00000402, $494C4C45, $47414C20, $494E5354, $52554354
	dc.l	$494F4E00, $00004EB9, $00000402, $5A45524F, $20444956, $49444500, $00004EB9, $00000402
	dc.l	$43484B20, $494E5354, $52554354, $494F4E00, $00004EB9, $00000402, $54524150, $5620494E
	dc.l	$53545255, $4354494F, $4E000000, $4EB90000, $04025052, $4956494C, $45474520, $56494F4C
	dc.l	$4154494F, $4E000000, $4EB90000, $04025452, $41434500, $00004EB9, $00000402, $4C494E45
	dc.l	$20313031, $3020454D, $554C4154, $4F520000, $4EB90000, $04024C49, $4E452031, $31313120
	dc.l	$454D554C, $41544F52, $00004EB9, $00000402, $4552524F, $52204558, $43455054, $494F4E00
	dc.l	$000046FC, $27004FEF, $FFF248E7, $FFFE4EBA, $024649EF, $004A4E68, $2F0847EF, $00404EBA
	dc.l	$013241FA, $02CA4EBA, $0AF6225C, $45D44EBA, $0B9A4EBA, $0A9249D2, $1C196A02, $524947D1
	dc.l	$08060000, $670E43FA, $02AD45EC, $00024EBA, $0B7A504C, $43FA02AE, $45EC0002, $4EBA0B6C
	dc.l	$43FA02B0, $45EC0002, $4EBA0B60, $22780000, $45EC0006, $4EBA00E8, $4EBA01BC, $43FA02A2
	dc.l	$2F0145D7, $4EBA0B44, $4EBA0A3C, $584F0806, $00066600, $00A845EF, $00044EBA, $0A083F01
	dc.l	$70034EBA, $09D4303C, $64307A07, $4EBA011A, $321F7011, $4EBA09C2, $303C6130, $7A064EBA
	dc.l	$0108303C, $73707A00, $2F0C45D7, $4EBA00FA, $584F0806, $00016714, $43FA0254, $45D74EBA
	dc.l	$0AEE43FA, $025545D4, $4EBA0AE0, $584F4EBA, $09B45241, $70014EBA, $09802038, $007841FA
	dc.l	$02434EBA, $00F22038, $007041FA, $023F4EBA, $00E64EBA, $09B22278, $000045D4, $5389613E
	dc.l	$4EBA0982, $7A199A41, $6B0A6146, $4EBA0058, $51CDFFFA, $08060005, $660860FE, $72004EBA
	dc.l	$09AE2ECB, $4CDF7FFF, $487AFFF0, $2F2FFFC4, $4E7543FA, $015645FA, $01FC4EFA, $0896223C
	dc.l	$00FFFFFF, $2409C481, $2242240A, $C4812442, $4E754FEF, $FFD041D7, $7EFF20FC, $28535029
	dc.l	$30FC3A20, $60184FEF, $FFD041D7, $7EFF30FC, $202B320A, $924C4EBA, $05B230FC, $3A207005
	dc.l	$72ECB5C9, $650272EE, $10C1321A, $4EBA05BA, $10FC0020, $51C8FFEA, $421841D7, $72004EBA
	dc.l	$09584FEF, $00304E75, $4FEFFFF0, $7EFF41D7, $30C030FC, $3A2010FC, $00EC221A, $4EBA0582
	dc.l	$421841D7, $72004EBA, $09305240, $51CDFFE0, $4FEF0010, $4E752200, $48414601, $6620514F
	dc.l	$2E882440, $43FA0021, $0C5A4EF9, $660843FA, $00102F52, $000445D7, $4EBA09B4, $504F4E75
	dc.l	$D0E8BFEC, $C8E000D0, $E83C756E, $64656669, $6E65643E, $E0005989, $B3CA650C, $0C520040
	dc.l	$650A548A, $B3CA64F4, $72004E75, $22120801, $000066EE, $4E754BF9, $00C00004, $4DEDFFFC
	dc.l	$4A5544D5, $69FC41FA, $00263018, $6A043A80, $60F87000, $2ABC4000, $00002C80, $2ABC4000
	dc.l	$00102C80, $2ABCC000, $00003C80, $4E758004, $81348220, $84048500, $87008B00, $8C818D00
	dc.l	$8F029011, $91009200, $00004400, $00000000, $00010010, $00110100, $01010110, $01111000
	dc.l	$10011010, $10111100, $11011110, $1111FFFF, $40000002, $00280028, $00000080, $00FF0EEE
	dc.l	$FFF200CE, $FFF20EEA, $FFF20E86, $FFF2EAE0, $FA01F026, $00EA4164, $64726573, $733A20E8
	dc.l	$BBECC000, $EA4C6F63, $6174696F, $6E3A20EC, $8300EA4D, $6F64756C, $653A20E8, $BFECC800
	dc.l	$EA43616C, $6C65723A, $20E8BBEC, $C000FA10, $E8757370, $3A20EC83, $00FA03E8, $73723A20
	dc.l	$EC8100EA, $56496E74, $3A2000EA, $48496E74, $3A200000, $02F70000, $00000000, $0000183C
	dc.l	$3C181800, $18006C6C, $6C000000, $00006C6C, $FE6CFE6C, $6C00187E, $C07C06FC, $180000C6
	dc.l	$0C183060, $C600386C, $3876CCCC, $76001818, $30000000, $00001830, $60606030, $18006030
	dc.l	$18181830, $600000EE, $7CFE7CEE, $00000018, $187E1818, $00000000, $00001818, $30000000
	dc.l	$00FE0000, $00000000, $00000038, $3800060C, $183060C0, $80007CC6, $CEDEF6E6, $7C001878
	dc.l	$18181818, $7E007CC6, $0C183066, $FE007CC6, $063C06C6, $7C000C1C, $3C6CFE0C, $0C00FEC0
	dc.l	$FC0606C6, $7C007CC6, $C0FCC6C6, $7C00FEC6, $060C1818, $18007CC6, $C67CC6C6, $7C007CC6
	dc.l	$C67E06C6, $7C00001C, $1C00001C, $1C000018, $18000018, $18300C18, $30603018, $0C000000
	dc.l	$FE0000FE, $00006030, $180C1830, $60007CC6, $060C1800, $18007CC6, $C6DEDCC0, $7E00386C
	dc.l	$C6C6FEC6, $C600FC66, $667C6666, $FC003C66, $C0C0C066, $3C00F86C, $6666666C, $F800FEC2
	dc.l	$C0F8C0C2, $FE00FE62, $607C6060, $F0007CC6, $C0C0DEC6, $7C00C6C6, $C6FEC6C6, $C6003C18
	dc.l	$18181818, $3C003C18, $1818D8D8, $7000C6CC, $D8F0D8CC, $C600F060, $60606062, $FE00C6EE
	dc.l	$FED6D6C6, $C600C6E6, $E6F6DECE, $C6007CC6, $C6C6C6C6, $7C00FC66, $667C6060, $F0007CC6
	dc.l	$C6C6C6D6, $7C06FCC6, $C6FCD8CC, $C6007CC6, $C07C06C6, $7C007E5A, $18181818, $3C00C6C6
	dc.l	$C6C6C6C6, $7C00C6C6, $C6C66C38, $1000C6C6, $D6D6FEEE, $C600C66C, $3838386C, $C6006666
	dc.l	$663C1818, $3C00FE86, $0C183062, $FE007C60, $60606060, $7C00C060, $30180C06, $02007C0C
	dc.l	$0C0C0C0C, $7C001038, $6CC60000, $00000000, $00000000, $00FF3030, $18000000, $00000000
	dc.l	$780C7CCC, $7E00E060, $7C666666, $FC000000, $7CC6C0C6, $7C001C0C, $7CCCCCCC, $7E000000
	dc.l	$7CC6FEC0, $7C001C36, $30FC3030, $78000000, $76CEC67E, $067CE060, $7C666666, $E6001800
	dc.l	$38181818, $3C000C00, $1C0C0C0C, $CC78E060, $666C786C, $E6001818, $18181818, $1C000000
	dc.l	$6CFED6D6, $C6000000, $DC666666, $66000000, $7CC6C6C6, $7C000000, $DC66667C, $60F00000
	dc.l	$76CCCC7C, $0C1E0000, $DC666060, $F0000000, $7CC07C06, $7C003030, $FC303036, $1C000000
	dc.l	$CCCCCCCC, $76000000, $C6C66C38, $10000000, $C6C6D6FE, $6C000000, $C66C386C, $C6000000
	dc.l	$C6C6CE76, $067C0000, $FC983064, $FC000E18, $18701818, $0E001818, $18001818, $18007018
	dc.l	$180E1818, $700076DC, $00000000, $00002279, $00000200, $0C59DEB2, $667270FE, $D05974FC
	dc.l	$76004841, $024100FF, $D241D241, $B240625C, $675E2031, $10006758, $47F10800, $48417000
	dc.l	$301BB253, $654C43F3, $08FE45E9, $FFFCE248, $C042B273, $00006514, $6204D6C0, $601A47F3
	dc.l	$0004200A, $908B6AE6, $594B600C, $45F300FC, $200A908B, $6AD847D2, $925B7400, $341BD3C2
	dc.l	$48414241, $4841D283, $70004E75, $70FF4E75, $48417000, $3001D680, $5283323C, $FFFF4841
	dc.l	$59416A8E, $70FF4E75, $26790000, $02000C5B, $DEB2664A, $D6D37800, $72007400, $45D351CC
	dc.l	$00061619, $7807D603, $D3415242, $B252620A, $65ECB42A, $00026712, $65E4584A, $B25262FA
	dc.l	$65DCB42A, $000265D6, $66F010EA, $0003670A, $51CFFFC6, $4E9464C0, $4E755348, $4E757000
	dc.l	$4E754EFA, $00244EFA, $0018760F, $3401E84A, $C44310FB, $205E51CF, $004C4E94, $64464E75
	dc.l	$48416104, $654A4841, $7404760F, $E5791801, $C84310FB, $403E51CF, $00044E94, $6532E579
	dc.l	$1801C843, $10FB402C, $51CF0004, $4E946520, $E5791801, $C84310FB, $401A51CF, $00044E94
	dc.l	$650EE579, $C24310FB, $100A51CF, $00044ED4, $4E753031, $32333435, $36373839, $41424344
	dc.l	$45464EFA, $00264EFA, $001A7407, $7018D201, $D10010C0, $51CF0006, $4E946504, $51CAFFEE
	dc.l	$4E754841, $61046518, $4841740F, $7018D241, $D10010C0, $51CF0006, $4E946504, $51CAFFEE
	dc.l	$4E754EFA, $00104EFA, $004847FA, $009A0241, $00FF6004, $47FA008C, $42007609, $381B3403
	dc.l	$924455CA, $FFFCD244, $94434442, $8002670E, $06020030, $10C251CF, $00064E94, $6510381B
	dc.l	$6ADC0601, $003010C1, $51CF0004, $4ED44E75, $47FA002E, $42007609, $281B3403, $928455CA
	dc.l	$FFFCD284, $94434442, $8002670E, $06020030, $10C251CF, $00064E94, $65D4281B, $6ADC609E
	dc.l	$3B9ACA00, $05F5E100, $00989680, $000F4240, $000186A0, $00002710, $FFFF03E8, $0064000A
	dc.l	$FFFF2710, $03E80064, $000AFFFF, $48C16008, $4EFA0006, $488148C1, $48E75060, $4EBAFD90
	dc.l	$66182E81, $4EBAFE22, $4CDF060A, $650A0803, $00036604, $4EFA00B6, $4E754CDF, $060A0803
	dc.l	$00026708, $47FA000A, $4EFA00B4, $70FF60DE, $3C756E6B, $6E6F776E, $3E0010FC, $002B51CF
	dc.l	$00064E94, $65D24841, $4A416700, $FE5A6000, $FE520803, $000366C0, $4EFAFE46, $48E7F810
	dc.l	$10D95FCF, $FFFC6E14, $67181620, $7470C403, $4EBB201A, $64EA4CDF, $081F4E75, $4E9464E0
	dc.l	$60F45348, $4E944CDF, $081F4E75, $47FAFDF4, $B702D402, $4EFB205A, $4E714E71, $47FAFEA4
	dc.l	$B702D402, $4EFB204A, $4E714E71, $47FAFE54, $B702D402, $4EFB203A, $53484E75, $47FAFF2E
	dc.l	$14030242, $0003D442, $4EFB2026, $4A406B08, $4A816716, $4EFAFF64, $4EFAFF78, $265A10DB
	dc.l	$57CFFFFC, $67D24E94, $64F44E75, $5248603C, $504B321A, $4ED3584B, $221A4ED3, $52486022
	dc.l	$504B321A, $6004584B, $221A6A08, $448110FC, $002D6004, $10FC002B, $51CF0006, $4E9465CA
	dc.l	$4ED351CF, $00064E94, $65C010D9, $51CFFFBC, $4ED44BF9, $00C00004, $4DEDFFFC, $4A516B10
	dc.l	$2A9941D2, $38184EBA, $01F643E9, $002060EC, $54494E63, $2A1926C5, $26D926D9, $36FC5D00
	dc.l	$47FA003A, $2A857000, $32194E93, $2ABC4000, $00007200, $4E932ABC, $C0000000, $70007603
	dc.l	$3C803419, $3C823419, $6AFA7200, $4EB32010, $51CBFFEE, $3ABC8174, $2A854E75, $2C802C80
	dc.l	$2C802C80, $2C802C80, $2C802C80, $51C9FFEE, $4E754CAF, $00030004, $48E76010, $4E6B0C2B
	dc.l	$005D000C, $66183413, $0242E000, $C2EB000A, $D441D440, $D4403682, $23D300C0, $00044CDF
	dc.l	$08064E75, $2F0B4E6B, $0C2B005D, $000C6612, $72003213, $02411FFF, $82EB000A, $20014840
	dc.l	$E248265F, $4E752F0B, $4E6B0C2B, $005D000C, $66183F00, $3013D06B, $000A0240, $5FFF3680
	dc.l	$23DB00C0, $000436DB, $301F265F, $4E752F0B, $4E6B0C2B, $005D000C, $66043741, $0008265F
	dc.l	$4E752F0B, $4E6B0C2B, $005D000C, $6606584B, $36C136C1, $265F4E75, $61D4487A, $FFAA48E7
	dc.l	$7E124E6B, $0C2B005D, $000C661C, $2A1B4C93, $005C4846, $4DF900C0, $00007200, $12186E0E
	dc.l	$6B284893, $001C2705, $4CDF487E, $4E7551CB, $000ED642, $DA860885, $001D2D45, $0004D244
	dc.l	$3C817200, $12186EE6, $67D80241, $001E4EFB, $1002DA86, $721D0385, $60206026, $602A6032
	dc.l	$603A1418, $60141818, $60D86036, $1218D241, $76804843, $CA834841, $8A813602, $2D450004
	dc.l	$60C00244, $07FF60BA, $024407FF, $00442000, $60B00244, $07FF0044, $400060A6, $00446000
	dc.l	$60A03F04, $1E98381F, $6098487A, $FEFA2F0C, $49FA0016, $4FEFFFF0, $41D77E0E, $4EBAFD3E
	dc.l	$4FEF0010, $285F4E75, $42184447, $0647000F, $90C72F08, $4EBAFF28, $205F7E0E, $4E75741E
	dc.l	$10181200, $E609C242, $3CB11000, $D000C042, $3CB10000, $51CCFFEA
	dc.w	$4E75
