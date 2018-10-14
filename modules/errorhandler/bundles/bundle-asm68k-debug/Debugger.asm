
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Debugging macros definitions file
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
			if strlen("\__param")<1
				__param: substr ,,"hex"			; if param is ommited, set it to "hex"
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