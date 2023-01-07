#!/usr/bin/sh
set -e

../../../utils/blobtoasm/blobtoasm.py ../MDShell.bin MDShell.Blob.asm -t MDShell.InjectTable.log -m MDShell.InjectData.log

mkdir -p bundle-asm68k
../../exec/cbundle bundle-asm68k.cbundle

mkdir -p bundle-as
../../exec/cbundle bundle-as.cbundle
