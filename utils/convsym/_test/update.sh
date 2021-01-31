set -e

convsym=../convsym

$convsym sonic1.sym sonic1.deb2.model -input asm68k_sym
zcat sonic2.lst.gz | $convsym - sonic2.deb2.model -input as_lst
zcat sonic2.lst.gz | $convsym - sonic2.log.model -input as_lst -output log
zcat sonic3k.lst.gz | $convsym - sonic3k.deb2.model -input as_lst

$convsym sonic1.sym sonic1.deb1.model -input asm68k_sym -output deb1
zcat sonic2.lst.gz | $convsym - sonic2.deb1.model -input as_lst -output deb1
zcat sonic3k.lst.gz | $convsym - sonic3k.deb1.model -input as_lst -output deb1 2> /dev/null

$convsym sonic1.sym sonic1.sym.log.model -input asm68k_sym -output log
$convsym sonic1.sym sonic1.sym.asm.model -input asm68k_sym -output asm

zcat s1built.lst.gz | $convsym - s1built.log.model -input asm68k_lst -output log -inopt "/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+"
$convsym test.lst test.log.model -input asm68k_lst -output log

zcat sonic1git.lst.gz | $convsym - sonic1git.lst.log.model -in asm68k_lst -out log -tolower -inopt "/localSign=@ /localJoin=. /ignoreMacroExp- /ignoreMacroDefs- /addMacrosAsOpcodes+ /processLocals+"
$convsym sonic1git.sym sonic1git.sym.log.model -in asm68k_sym -out log -tolower -inopt "/localSign=@ /localJoin=. /processLocals+"
