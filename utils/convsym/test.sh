#!/bin/sh
set -e

cd _test
convsym=../convsym

if [ ! -z "$USE_VALGRIND" ]; then
	convsym="valgrind ../convsym"
fi


echo -n "Testing log->log symbol generation (logtest.in.log)... "
{
	$convsym logtest.in.log logtest.out.log -input log -output log -inopt "/separator=: /useDecimal+"
	diff -q logtest.out.log logtest.out.log.model 1>&2
}
echo "OK"


echo -n "Testing asm68k_lst->log symbol generation (test.lst)... "
{
	$convsym test.lst test.log -input asm68k_lst -output log
	diff -q test.log test.log.model	1>&2
} >/dev/null
echo "OK"


echo -n "Testing asm68k_lst->log symbol generation (Sonic 1 Hivebrain Disassembly)... "
{
	zcat s1built.lst.gz | $convsym - s1built.log -input asm68k_lst -output log -inopt "/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+"
	diff -q s1built.log s1built.log.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing asm68k_sym->deb2 symbol generation (Sonic 1 Hivebrain Disassembly)... "
{
	$convsym sonic1.sym sonic1.deb2 -input asm68k_sym
	diff -q sonic1.deb2 sonic1.deb2.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing as_lst_legacy->deb2 symbol generation (Sonic 2 Disassembly)... "
{
	zcat sonic2.lst.gz  | $convsym - sonic2.deb2 -input as_lst_legacy
	diff -q sonic2.deb2 sonic2.deb2.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing as_lst_legacy->deb2 symbol generation (Sonic 3K Disassembly)... "
{
	zcat sonic3k.lst.gz | $convsym - sonic3k.deb2 -input as_lst_legacy
	diff -q sonic3k.deb2 sonic3k.deb2.model 1>&2
} >/dev/null
echo "OK"

echo -n "Testing asm68k_sym->deb1 symbol generation (Sonic 1 Hivebrain Disassembly)... "
{
	$convsym sonic1.sym sonic1.deb1 -input asm68k_sym -output deb1
	diff -q sonic1.deb1 sonic1.deb1.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing as_lst_legacy->deb1 symbol generation (Sonic 2 Disassembly)... "
{
	zcat sonic2.lst.gz  | $convsym - sonic2.deb1 -input as_lst_legacy -output deb1
	diff -q sonic2.deb1 sonic2.deb1.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing as_lst_legacy->deb1 symbol generation (Sonic 3K Disassembly)... "
{
	zcat sonic3k.lst.gz | $convsym - sonic3k.deb1 -input as_lst_legacy -output deb1 2> /dev/null
	diff -q sonic3k.deb1 sonic3k.deb1.model 1>&2
} >/dev/null
echo "OK"

echo -n "Testing asm68k_sym->log symbol generation (Sonic 1 Hivebrain Disassembly)... "
{
	$convsym sonic1.sym sonic1.sym.log -input asm68k_sym -output log
	diff -q sonic1.sym.log sonic1.sym.log.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing asm68k_sym->asm symbol generation (Sonic 1 Hivebrain Disassembly)... "
{
	$convsym sonic1.sym sonic1.sym.asm -input asm68k_sym -output asm
	diff -q sonic1.sym.asm sonic1.sym.asm.model 1>&2
} >/dev/null
echo "OK"


echo -n "Testing asm68k_lst->log symbol generation (Sonic 1 Git Disassembly)... "
{
	zcat sonic1git.lst.gz | $convsym - sonic1git.lst.log -in asm68k_lst -out log -tolower -inopt "/localSign=@ /localJoin=. /ignoreMacroExp- /ignoreMacroDefs- /addMacrosAsOpcodes+ /processLocals+"
	diff -q sonic1git.lst.log sonic1git.lst.log.model
} >/dev/null
echo "OK"

echo -n "Testing asm68k_sym->log symbol generation (Sonic 1 Git Disassembly)... "
{
	$convsym sonic1git.sym sonic1git.sym.log -in asm68k_sym -out log -tolower -inopt "/localSign=@ /localJoin=. /processLocals+"	
	diff -q sonic1git.sym.log sonic1git.sym.log.model
} >/dev/null
echo "OK"
