cp ../ErrorHandler.bin _test/ErrorHandler.bin

echo --- BUILDING BUNDLE-ASM68K ---
../../exec/cbundle bundle-asm68k.asm
cp ../ErrorHandler.bin bundle-asm68k/ErrorHandler.bin

echo --- BUILDING BUNDLE-ASM68K-DEBUG ---
../../exec/cbundle bundle-asm68k-debug.asm
cp ../ErrorHandler.Debug.bin bundle-asm68k-debug/ErrorHandler.bin

echo --- BUILDING BUNDLE-AS ---
../../exec/cbundle bundle-as.asm
cp ../ErrorHandler.bin bundle-as/ErrorHandler.bin
