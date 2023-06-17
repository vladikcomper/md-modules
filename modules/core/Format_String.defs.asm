
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
