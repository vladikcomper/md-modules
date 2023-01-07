@echo off

python ..\..\..\utils\blobtoasm\blobtoasm.py ..\MDShell.bin MDShell.Blob.asm -t MDShell.InjectTable.log -m MDShell.InjectData.log

md bundle-asm68k
..\..\exec\cbundle bundle-asm68k.cbundle

md bundle-as
..\..\exec\cbundle bundle-as.cbundle
