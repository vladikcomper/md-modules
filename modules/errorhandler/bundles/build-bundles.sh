#!/usr/bin/sh
set -e

../../../utils/blobtoasm/blobtoasm.py ../ErrorHandler.bin ErrorHandler.Blob.asm
../../../utils/blobtoasm/blobtoasm.py ../ErrorHandler.Debug.bin ErrorHandler.Debug.Blob.asm
../../../utils/blobtoasm/blobtoasm.py -m ErrorHandler.ExtSymbols.InjectData.txt -t ErrorHandler.ExtSymbols.InjectTable.log ../ErrorHandler.ExtSymbols.bin ErrorHandler.ExtSymbols.Blob.asm

echo --- BUILDING BUNDLE-ASM68K ---
mkdir -p bundle-asm68k
../../exec/cbundle bundle-asm68k.cbundle

echo --- BUILDING BUNDLE-ASM68K-DEBUG ---
mkdir -p bundle-asm68k-debug
../../exec/cbundle bundle-asm68k-debug.cbundle

echo --- BUILDING BUNDLE-AS ---
mkdir -p bundle-as
../../exec/cbundle bundle-as.cbundle

echo --- BUILDING BUNDLE-ASM68K-EXTSYM ---
mkdir -p bundle-asm68k-extsym
../../exec/cbundle bundle-asm68k-extsym.cbundle

echo --- BUILDING BUNDLE-AS-EXTSYM ---
mkdir -p bundle-as-extsym
../../exec/cbundle bundle-as-extsym.cbundle
