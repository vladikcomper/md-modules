#!/usr/bin/env python3
from typing import cast
from argparse import ArgumentParser
from dataclasses import dataclass
import subprocess

BASE_DIR = '_test'

import sys
sys.path.append('../core-py')
from test_framework import Test, Command, CommandResult, CheckMatch, DataSource, File, Buffer, archiveDirectory, unarchiveDirectory, getUsedFilesList, runTests, setBaseDir


@dataclass
class ConvSym(Command):
	options: 'tuple[str, ...]' = ()

	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		use_stdin = not isinstance(input, File)
		use_stdout = not isinstance(output, File)

		# Execute ConvSym
		args = ['./convsym', '-', '-', *self.options]
		args[1] = '-' if use_stdin else str(cast(File, input).getPath())
		args[2] = '-' if use_stdout else str(cast(File, output).getPath())
		result = subprocess.run(args, input=None if isinstance(input, File) else input.read(), text=False, capture_output=True)

		# Collect output
		if result.returncode != 0: return (False, f'ConvSym returned non-zero exit code (stderr="{result.stderr}")')
		if use_stdout: output.write(result.stdout)
		return (True, output)


tests: 'tuple[Test, ...]' = (
	Test(
		description = 'log->log symbol generation (sanity check)',
		pipeline=(
			ConvSym(
				input = Buffer(b'0: Start\n3FFFFF: End\n'),
				options = ('-input', 'log', '-output', 'log'),
			),
			CheckMatch(output=Buffer(b'0: Start\n3FFFFF: End\n'), text=True)
		),
	),
	Test(
		description = 'log->asm symbol generation (sanity check)',
		pipeline=(
			ConvSym(
				input = Buffer(b'0: Start\n3FFFFF: End\n'),
				options = ('-input', 'log', '-output', 'asm'),
			),
			CheckMatch(output=Buffer(b'Start:\tequ\t$0\nEnd:\tequ\t$3FFFFF\n'), text=True)
		),
	),
	Test(
		description = 'log->log symbol generation (logtest-simple.log)',
		pipeline=(
			ConvSym(
				input = File('input/logtest-simple.log'),
				output = File('output/logtest-simple.log'),
				options = ('-input', 'log', '-output', 'log'),
			),
			CheckMatch(output=File('output-expected/logtest-simple.log'), text=True)
		),
	),
	Test(
		description = 'log->log symbol generation (logtest-advanced.log)',
		pipeline=(
			ConvSym(
				input = File('input/logtest-advanced.log'),
				output = File('output/logtest-advanced.log'),
				options = ('-input', 'log', '-output', 'log', '-inopt', '/separator=: /useDecimal+'),
			),
			CheckMatch(output=File('output-expected/logtest-advanced.log'), text=True)
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (asm68k-lst-sample.lst)',
		pipeline=(
			ConvSym(
				input = File('input/asm68k-lst-sample.lst'),
				output = File('output/asm68k-lst-sample.log'),
				options = ('-input', 'asm68k_lst', '-output', 'log'),
			),
			CheckMatch(output=File('output-expected/asm68k-lst-sample.log'), text=True)
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (Sonic 1 Hivebrain 2005 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.lst'),
				output = File('output/sonic-1-hivebrain-2005.log'),
				options = ('-input', 'asm68k_lst', '-output', 'log', '-inopt', '/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+'),
			),
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.log'), text=True),
		),
	),
	Test(
		description = 'asm68k_sym->deb2 symbol generation (Sonic 1 Hivebrain 2005 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.sym'),
				output = File('output/sonic-1-hivebrain-2005.deb2'),
				options = ('-input', 'asm68k_sym'),
			),
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.deb2')),
		),
	),
	Test(
		description = 'as_lst_exp->deb2 symbol generation (Sonic 2 Xenowhirl Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2.lst'),
				output = File('output/sonic-2.deb2'),
				options = ('-input', 'as_lst_exp'),
			),
			CheckMatch(output=File('output-expected/sonic-2.deb2')),
		),
	),
	Test(
		description = 'as_lst_exp->deb2 symbol generation (Sonic 3K Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k.lst'),
				output = File('output/sonic-3k.deb2'),
				options = ('-input', 'as_lst_exp'),
			),
			CheckMatch(output=File('output-expected/sonic-3k.deb2')),
		),
	),
	Test(
		description = 'asm68k_sym->deb1 symbol generation (Sonic 1 Hivebrain 2005 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.sym'),
				output = File('output/sonic-1-hivebrain-2005.deb1'),
				options = ('-input', 'asm68k_sym', '-output', 'deb1'),
			),
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.deb1')),
		),
	),
	Test(
		description = 'as_lst_exp->deb1 symbol generation (Sonic 2 Xenowhirl Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2.lst'),
				output = File('output/sonic-2.deb1'),
				options = ('-input', 'as_lst_exp', '-output', 'deb1'),
			),
			CheckMatch(output=File('output-expected/sonic-2.deb1')),
		),
	),
	Test(
		description = 'as_lst_exp->deb1 symbol generation (Sonic 3K Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k.lst'),
				output = File('output/sonic-3k.deb1'),
				options = ('-input', 'as_lst_exp', '-output', 'deb1'),
			),
			CheckMatch(output=File('output-expected/sonic-3k.deb1')),
		),
	),
	Test(
		description = 'asm68k_sym->log symbol generation (Sonic 1 Hivebrain 2005 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.sym'),
				output = File('output/sonic-1-hivebrain-2005.sym.log'),
				options = ('-input', 'asm68k_sym', '-output', 'log'),
			),
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.sym.log'), text=True),
		),
	),
	Test(
		description = 'asm68k_sym->asm symbol generation (Sonic 1 Hivebrain Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.sym'),
				output = File('output/sonic-1-hivebrain-2005.sym.asm'),
				options = ('-input', 'asm68k_sym', '-output', 'asm'),
			),
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.sym.asm'), text=True),
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (Sonic 1 Git 2018 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-git-2018.lst'),
				output = File('output/sonic-1-git-2018.lst.log'),
				options = ('-in', 'asm68k_lst', '-out', 'log', '-tolower', '-inopt', '/localSign=@ /localJoin=. /ignoreMacroExp- /ignoreMacroDefs- /addMacrosAsOpcodes+ /processLocals+')
			),
			CheckMatch(output=File('output-expected/sonic-1-git-2018.lst.log'), text=True),
		),
	),
	Test(
		description = 'asm68k_sym->log symbol generation (Sonic 1 Git 2018 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-git-2018.sym'),
				output = File('output/sonic-1-git-2018.sym.log'),
				options = ('-in', 'asm68k_sym', '-out', 'log', '-tolower', '-inopt', '/localSign=@ /localJoin=. /processLocals+'),
			),
			CheckMatch(output=File('output-expected/sonic-1-git-2018.sym.log'), text=True),
		),
	),
	Test(
		description = 'asm68k_sym<->asm68k_lst symbols match (Sonic 1 Hivebrain 2005 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.lst'),
				output = File('output/sonic-1-hivebrain-2005.lst.deb2'),
				options = ('-input', 'asm68k_lst', '-output', 'deb2', '-tolower', '-inopt', '/processLocals-'),
			),
			ConvSym(
				input = File('input/sonic-1-hivebrain-2005.sym'),
				output = File('output/sonic-1-hivebrain-2005.lst.deb2'),
				options = ('-input', 'asm68k_sym', '-output', 'deb2', '-tolower'),
			),
			CheckMatch(output=File('output/sonic-1-hivebrain-2005.lst.deb2')),
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (Sonic 1 Git 2022 Disassembly - ASM68K)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-git-2022-asm68k.lst'),
				output = File('output/sonic-1-git-2022-asm68k.lst.log'),
				options = ('-in', 'asm68k_lst', '-out', 'log')
			),
			CheckMatch(output=File('output-expected/sonic-1-git-2022-asm68k.lst.log'), text=True),
		),
	),
	Test(
		description = 'asm68k_sym->log symbol generation (Sonic 1 Git 2022 Disassembly - ASM68K)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-git-2022-asm68k.sym'),
				output = File('output/sonic-1-git-2022-asm68k.sym.log'),
				options = ('-in', 'asm68k_sym', '-out', 'log')
			),
			CheckMatch(output=File('output-expected/sonic-1-git-2022-asm68k.sym.log'), text=True),
		),
	),
	Test(
		description = 'as_lst->log symbol generation (Sonic 1 Git 2022 Disassembly - AS)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-1-git-2022-as.lst'),
				output = File('output/sonic-1-git-2022-as.log'),
				options = ('-in', 'as_lst', '-out', 'log', '-exclude', '-filter', 'z.+')
			),
			CheckMatch(output=File('output-expected/sonic-1-git-2022-as.log'), text=True),
		),
	),
	Test(
		description = 'as_lst->log symbol generation (Sonic 2 Git 2022 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2-git-2022.lst'),
				output = File('output/sonic-2-git-2022.log'),
				options = ('-in', 'as_lst', '-out', 'log', '-exclude', '-filter', '(z.+)|(cf[A-Z].+)')
			),
			CheckMatch(output=File('output-expected/sonic-2-git-2022.log'), text=True),
		),
	),
	Test(
		description = 'as_lst->log symbol generation (Sonic 3K 2022 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k-git-2022.lst'),
				output = File('output/sonic-3k-git-2022.log'),
				options = ('-in', 'as_lst', '-out', 'log', '-exclude', '-filter', '(z.+)|(mus_.+)|(sfx_.+)|(cf[A-Z].+)')
			),
			CheckMatch(output=File('output-expected/sonic-3k-git-2022.log'), text=True),
		),
	),
	Test(
		description = 'as_lst_exp->log symbol generation (Sonic 2 Git 2022 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2-git-2022.lst'),
				output = File('output/sonic-2-git-2022.as_lst_exp.log'),
				options = ('-in', 'as_lst_exp', '-out', 'log')
			),
			CheckMatch(output=File('output-expected/sonic-2-git-2022.as_lst_exp.log'), text=True),
		),
	),
	Test(
		description = 'as_lst_exp->log symbol generation (Sonic 3K 2022 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k-git-2022.lst'),
				output = File('output/sonic-3k-git-2022.as_lst_exp.log'),
				options = ('-in', 'as_lst_exp', '-out', 'log')
			),
			CheckMatch(output=File('output-expected/sonic-3k-git-2022.as_lst_exp.log'), text=True),
		),
	),
	Test(
		description = 'asm68k_sym->log no-process-locals test (Custom Kernel)',
		pipeline=(
			ConvSym(
				input = File('input/kernel.sym'),
				output = File('output/kernel.log'),
				options = ('-in', 'asm68k_sym', '-out', 'log', '-inopt', '/processLocals-')
			),
			CheckMatch(output=File('output-expected/kernel.log'), text=True),
		),
	),
)


def main():
	arg_parser = ArgumentParser(description='Handles tests for ConvSym utility')
	arg_parser.add_argument('-c', '--command', choices=('run', 'update', 'list_files'), default='run')
	args = arg_parser.parse_args()

	setBaseDir(BASE_DIR)

	if args.command == 'run':
		unarchiveDirectory('input', skipIfExists=True)
		unarchiveDirectory('output-expected', skipIfExists=True)

		success = runTests(tests)

		if not success:
			exit(1)

	elif args.command == 'update':
		archiveDirectory('input')
		archiveDirectory('output-expected')

	elif args.command == 'list_files':
		print('\n'.join(getUsedFilesList(tests)))


if __name__ == '__main__':
	main()
