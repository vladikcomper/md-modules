
; WARNING! This blocks are intended to compile if referenced anywhere in the code.
;	However, as of AS version 1.42 [Bld 55], "IFUSED" directive doesn't work properly.

; --------------------------------------------------------------
;	ifused ErrorHandler___extern__ScrollConsole
ErrorHandler___extern__ScrollConsole:

;	endif

; --------------------------------------------------------------
;	ifused ErrorHandler___extern__Console_Only
ErrorHandler___extern__Console_Only:
	dc.l	$46FC2700, $4FEFFFF2, $48E7FFFE, $47EF003C
	jsr		ErrorHandler___global__ErrorHandler_SetupVDP(pc)
	jsr		ErrorHandler___global__Error_InitConsole(pc)
	dc.l	$4CDF7FFF, $487A0008, $2F2F0012, $4E7560FE
;	endif

; --------------------------------------------------------------
;	ifused ErrorHandler___extern__VSync
ErrorHandler___extern__VSync:
	dc.l	$41F900C0, $000444D0, $6BFC44D0, $6AFC4E75
;	endif
