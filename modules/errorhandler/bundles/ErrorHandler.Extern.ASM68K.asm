
	if ref(ErrorHandler.__extern__ScrollConsole)
ErrorHandler.__extern__ScrollConsole:

	endc

	if ref(ErrorHandler.__extern__Console_Only)
ErrorHandler.__extern__Console_Only:
	dc.l	$46FC2700, $4FEFFFF2, $48E7FFFE, $47EF003C
	jsr		ErrorHandler.__global__ErrorHandler_SetupVDP(pc)
	jsr		ErrorHandler.__global__Error_InitConsole(pc)
	dc.l	$4CDF7FFF, $487A0008, $2F2F0012, $4E7560FE
	endc

	if ref(ErrorHandler.__extern__VSync)
ErrorHandler.__extern__VSync:
	dc.l	$41F900C0, $000444D0, $6BFC44D0, $6AFC4E75
	endc
