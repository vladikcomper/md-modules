@echo off

python3 ..\..\..\utils\blobtoasm\blobtoasm.py ..\ErrorHandler.bin ErrorHandler.Blob.asm
python3 ..\..\..\utils\blobtoasm\blobtoasm.py ..\ErrorHandler.Debug.bin ErrorHandler.Debug.Blob.asm

echo --- BUILDING BUNDLE-ASM68K ---
md bundle-asm68k
..\..\exec\cbundle bundle-asm68k.cbundle

echo --- BUILDING BUNDLE-ASM68K-DEBUG ---
md bundle-asm68k-debug
..\..\exec\cbundle bundle-asm68k-debug.cbundle


echo --- BUILDING BUNDLE-AS ---
md bundle-as
..\..\exec\cbundle bundle-as.cbundle
