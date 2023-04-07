#!/usr/bin/sh
set -e

# Normal version
wine ../exec/asm68k.exe /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- ErrorHandler.asm, ErrorHandler.bin, , ErrorHandler.lst
../exec/convsym ErrorHandler.lst "bundles/ErrorHandler.Global.ASM68K.asm" -input asm68k_lst -inopt "/processLocals-" -output asm -outopt "ErrorHandler.%s: equ ErrorHandler+$%X" -inopt "/processLocals-" -filter "__global_.+"
../exec/convsym ErrorHandler.lst "bundles/ErrorHandler.Global.AS.asm" -input asm68k_lst -inopt "/processLocals-" -output asm -outopt "ErrorHandler_%s: label ErrorHandler+$%X" -inopt "/processLocals-" -filter "__global_.+"

# "External Symbol Table" version
wine ../exec/asm68k.exe /k /m /o c+ /e _USE_SYMBOL_DATA_REF_=1 /e SymbolData_Ptr=0 /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- ErrorHandler.asm, ErrorHandler.ExtSymbols.bin, ErrorHandler.ExtSymbols.sym, ErrorHandler.ExtSymbols.lst
../exec/convsym ErrorHandler.ExtSymbols.sym "bundles/ErrorHandler.ExtSymbols.Global.ASM68K.asm" -input asm68k_sym -inopt "/processLocals-" -output asm -outopt "ErrorHandler.%s: equ ErrorHandler+$%X" -inopt "/processLocals-" -filter "__global_.+"
../exec/convsym ErrorHandler.ExtSymbols.sym "bundles/ErrorHandler.ExtSymbols.Global.AS.asm" -input asm68k_sym -inopt "/processLocals-" -output asm -outopt "ErrorHandler_%s: label ErrorHandler+$%X" -inopt "/processLocals-" -filter "__global_.+"
../exec/convsym ErrorHandler.ExtSymbols.sym "bundles/ErrorHandler.ExtSymbols.InjectTable.log" -input asm68k_sym -inopt "/processLocals-" -output asm -outopt "%s: %X" -inopt "/processLocals-" -filter '__inject_.+'

# Debug version
wine ../exec/asm68k.exe /k /e __DEBUG__ /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- ErrorHandler.asm, ErrorHandler.Debug.bin, , ErrorHandler.Debug.lst
../exec/convsym ErrorHandler.Debug.lst "bundles/ErrorHandler.Debug.Global.ASM68K.asm" -input asm68k_lst -output asm -outopt "ErrorHandler.%s: equ ErrorHandler+$%X" -inopt "/processLocals-" -filter "__global_.+"
