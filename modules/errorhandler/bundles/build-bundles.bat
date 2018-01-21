@echo off

copy /Y /B ..\errorhandler.bin _test\ErrorHandler.bin

echo --- BUILDING BUNDLE-ASM68K ---
..\..\exec\cbundle bundle-asm68k.asm
copy /Y /B ..\errorhandler.bin bundle-asm68k\ErrorHandler.bin

echo --- BUILDING BUNDLE-ASM68K-DEBUG ---
..\..\exec\cbundle bundle-asm68k-debug.asm
copy /Y /B ..\errorhandler.debug.bin bundle-asm68k-debug\ErrorHandler.bin


echo --- BUILDING BUNDLE-AS ---
..\..\exec\cbundle bundle-as.asm
copy /Y /B ..\errorhandler.bin bundle-as\ErrorHandler.bin
