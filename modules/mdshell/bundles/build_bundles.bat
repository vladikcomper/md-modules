@echo off

python ..\..\..\utils\blobtoasm\blobtoasm.py ..\MDShell.bin MDShell.Blob.asm -t MDShell.InjectTable.log -m MDShell.InjectData.log

md bundle-asm68k
..\..\exec\cbundle MDShell.asm -def MD-SHELL -def BUNDLE-ASM68K -out bundle-asm68k\MDShell.asm

md bundle-as
..\..\exec\cbundle MDShell.asm -def MD-SHELL -def BUNDLE-AS -out bundle-as\MDShell.asm
