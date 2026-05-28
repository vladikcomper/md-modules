	if def(_FORMAT_STRING_DEFS)=0
_FORMAT_STRING_DEFS:	equ	1

; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
;
; (c) 2016-2023, Vladikcomper
; ---------------------------------------------------------------
; String formatter module (definitions only)
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Constants
; ---------------------------------------------------------------

_hex	equ		$80
_dec	equ		$90
_bin	equ		$A0
_sym	equ		$B0
_disp	equ		$C0
_str	equ		$D0

byte	equ		0
word	equ		1
long	equ		3

; for number formatters ...
signed	equ		8

; for symbol formatters ...
split	equ		8				; display symbol/offset only, don't draw displacement yet ...
forced	equ		4				; display <unknown> if symbol was not found

; for symbol displacement or offset formatters ...
weak	equ		8				; don't draw offset (for use with _sym|forced, see above)

; ---------------------------------------------------------------
__FSTRING_GenerateArgumentsCode:	macro string

	__pos:	= instr(\string,'%<')		; token position
	__stack:= 0						; size of actual stack
	__sp:	= 0						; stack displacement

	pusho
	opt	ae-		; make sure "automatic even" is disabled as this disrupts string generation

	; Parse string itself
	while (__pos)

		; Retrive expression in brackets following % char
    	__endpos:	= instr(__pos+1,\string,'>')
    	if __endpos=0
			inform 3,'Missing a closing bracket after %<'
    	endif
    	__midpos:	= instr(__pos+5,\string,' ')
    	if (__midpos<1)|(__midpos>__endpos)
			__midpos: = __endpos
    	endif
		__substr:	substr	__pos+1+1,__endpos-1,\string			; .type ea param
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %(.w d0 hex) )
		if "\__type">>8="."
			__operand:	substr	__pos+1+1,__midpos-1,\string			; .type ea
			__param:	substr	__midpos+1,__endpos-1,\string			; param

			if instr("\__operand","(sp)")|instr("\__operand","(SP)")
				; Referring to (SP) may get unexpected results because stack is already shifted at this point
				; Using -(SP) and (SP)+ will crash because of stack corruption.
				inform 3,'Cannot use (SP) in a formatted string'
			endif

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
				inform 3,'Unrecognized type in string operand: %<\__substr>'
			endif
		endif

		__pos:	= instr(__pos+1,\string,'%<')
	endw

	; Generate stack code
	rept __stack
		popp	__command
		\__command
	endr

	popo	; restore previous options

	endm

; ---------------------------------------------------------------
__FSTRING_GenerateDecodedString:	macro string, addnewline

	__lpos:	= 1							; start position
	__pos:	= instr(\string,'%<')		; token position

	while (__pos)

		; Write part of string before % token
		__substr:	substr	__lpos,__pos-1,\string
		dc.b	"\__substr"

		; Retrive expression in brakets following % char
    	__endpos:	= instr(__pos+1,\string,'>')
    	__midpos:	= instr(__pos+5,\string,' ')
    	if (__midpos<1)|(__midpos>__endpos)
			__midpos: = __endpos
    	endif
		__type:		substr	__pos+1+1,__pos+1+1+1,\string			; .type

		; Expression is an effective address (e.g. %<.w d0 hex> )
		if "\__type">>8="."    
			__param:	substr	__midpos+1,__endpos-1,\string			; param
			
			; Validate format setting ("param")
			if strlen("\__param")<1
				__param: substr ,,"hex"			; if param is ommited, set it to "hex"
			elseif strcmp("\__param","signed")
				__param: substr ,,"hex+signed"	; if param is "signed", correct it to "hex+signed"
			endif

			if (\__param < $80)
#ifdef BUNDLE-AXM68K
## For AXM68K compatibility, we replace "dec" with "deci"
				inform	2,"Illegal operand format setting: ""\__param\"". Expected ""hex"", ""deci"", ""bin"", ""sym"", ""str"" or their derivatives."
#else
				inform	2,"Illegal operand format setting: ""\__param\"". Expected ""hex"", ""dec"", ""bin"", ""sym"", ""str"" or their derivatives."
#endif
			endif

			if "\__type"=".b"
				dc.b	\__param
			elseif "\__type"=".w"
				dc.b	\__param|1
			else
				dc.b	\__param|3
			endif

		; Expression is an inline constant (e.g. %<endl> )
		else
			__substr:	substr	__pos+1+1,__endpos-1,\string
			dc.b	\__substr
		endif

		__lpos:	= __endpos+1
		__pos:	= instr(__pos+1,\string,'%<')
	endw

	; Write part of string before the end
	__substr:	substr	__lpos,,\string
	dc.b	"\__substr"
	if addnewline
		dc.b	endl
	endif
	dc.b	0

	endm

	endif	; _FORMAT_STRING_DEFS