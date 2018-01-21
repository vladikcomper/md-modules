################################################################
## Bundle compilation script for use in ASM68K-based programs ##
################################################################

#define DEBUG
#define BUNDLE-ASM68K

#file bundle-asm68k-debug\Debugger.asm
#include Debugger.asm
#endf

#file bundle-asm68k-debug\ErrorHandler.asm
#include ErrorHandler.asm
#endf
