#!/usr/bin/sh
set -e

../../../utils/blobtoasm/blobtoasm.py ../ErrorHandler.bin ErrorHandler.Blob.asm
../../../utils/blobtoasm/blobtoasm.py ../ErrorHandler.Debug.bin ErrorHandler.Debug.Blob.asm

echo --- BUILDING BUNDLE-ASM68K ---
mkdir -p bundle-asm68k
../../exec/cbundle bundle-asm68k.cbundle

echo --- BUILDING BUNDLE-ASM68K-DEBUG ---
mkdir -p bundle-asm68k-debug
../../exec/cbundle bundle-asm68k-debug.cbundle

echo --- BUILDING BUNDLE-AS ---
mkdir -p bundle-as
../../exec/cbundle bundle-as.cbundle
