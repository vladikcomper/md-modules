@echo off

..\exec\asm68k.exe /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- MDShell.asm, MDShell.bin, MDShell.sym, MDShell.lst

rem Collect global symbols for MDShell bundle
..\exec\convsym.exe MDShell.sym "bundles\MDShell.Global.ASM68K.asm" -output asm -outopt "ErrorHandler.%s equ $%X" -filter "__global_.+"
..\exec\convsym.exe MDShell.sym "bundles\MDShell.Global.AS.asm" -output asm -outopt "ErrorHandler_%s label $%X" -filter "__global_.+"

rem Collect offsets for injectable symbols
..\exec\convsym.exe MDShell.sym "bundles\MDShell.InjectTable.log" -output asm -outopt "%s: %X" -filter "__(inject|blob)_.+"
pause