wine ../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- ErrorHandler.asm, ErrorHandler.bin, , ErrorHandler.lst
../exec/convsym ErrorHandler.lst "bundles/ErrorHandler.Global.ASM68K.asm" -input asm68k_lst -inopt "/processLocals-" -output asm -outopt "ErrorHandler.%s equ ErrorHandler+$%X" -filter "__global_.+"
../exec/convsym ErrorHandler.lst "bundles/ErrorHandler.Global.AS.asm" -input asm68k_lst -inopt "/processLocals-" -output asm -outopt "ErrorHandler_%s: label ErrorHandler+$%X" -filter "__global_.+"

wine ../exec/asm68k.exe /k /e __DEBUG__ /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- ErrorHandler.asm, ErrorHandler.Debug.bin, , ErrorHandler.Debug.lst
../exec/convsym ErrorHandler.Debug.lst "bundles/ErrorHandler.Debug.Global.ASM68K.asm" -input asm68k_lst -output asm -outopt "ErrorHandler.%s equ ErrorHandler+$%X" -inopt "/processLocals-" -filter "__global_.+"
