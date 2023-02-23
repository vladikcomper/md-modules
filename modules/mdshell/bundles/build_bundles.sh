#!/usr/bin/sh
set -e

../../../utils/blobtoasm/blobtoasm.py ../MDShell.bin MDShell.Blob.asm -t MDShell.InjectTable.log -m MDShell.InjectData.log

mkdir -p bundle-asm68k
../../exec/cbundle MDShell.asm -def MD-SHELL -def BUNDLE-ASM68K -out bundle-asm68k/MDShell.asm

mkdir -p bundle-as
../../exec/cbundle MDShell.asm -def MD-SHELL -def BUNDLE-AS -out bundle-as/MDShell.asm
