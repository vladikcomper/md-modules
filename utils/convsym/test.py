#!/usr/bin/env python3
import typing
import subprocess
import filecmp
import tarfile
from pathlib import Path
from dataclasses import dataclass

BASE_DIR = '_test'

CompareResult = tuple[typing.Literal[True], None] | tuple[typing.Literal[False], str]

class DataSource:
	def read(self) -> bytes: raise Exception('Not implemented')
	def write(self, data: bytes): raise Exception('Not implemented')
	def cmp(self, other) -> CompareResult:
		data1, data2 = self.read(), typing.cast(DataSource, other).read()
		if data1 != data2:
			return (False, f'Expected "{data2}", got "{data1}"') if len(data1) + len(data2) < 512 else (False, "Expected data to match")
		return (True, None)

@dataclass
class File(DataSource):
	path: str
	def read(self) -> bytes: return self.getPath().read_bytes()
	def write(self, data: bytes): return self.getPath().write_bytes(data)
	def getPath(self) -> Path: return Path(BASE_DIR, self.path)
	def cmp(self, other) -> CompareResult:
		if isinstance(other, File): # Slight optimization if other data source is also file
			return (True, None) if filecmp.cmp(self.getPath(), other.getPath()) else (False, f'Expected "{self.getPath()}" to match "{other.getPath()}"')
		return super().cmp(other)

@dataclass
class Buffer(DataSource):
	value: bytes = bytes()
	def read(self) -> bytes: return self.value
	def write(self, data: bytes): self.value = data

CommandResult = tuple[typing.Literal[True], DataSource] | tuple[typing.Literal[False], str]

@dataclass(kw_only=True)
class Command:
	output: DataSource | None = None
	input: DataSource | None = None

	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		return (False, 'Unable to execute command: not implemented')

@dataclass
class ConvSym(Command):
	options: tuple[str, ...] = ()

	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		use_stdin = not isinstance(input, File)
		use_stdout = not isinstance(output, File)

		# Execute ConvSym
		args = ['./convsym', '-', '-', *self.options]
		args[1] = '-' if use_stdin else str(typing.cast(File, input).getPath())
		args[2] = '-' if use_stdout else str(typing.cast(File, output).getPath())
		result = subprocess.run(args, input=None if isinstance(input, File) else input.read(), text=False, capture_output=True)

		# Collect output
		if result.returncode != 0: return (False, f'ConvSym returned non-zero exit code (stderr="{result.stderr}")')
		if use_stdout: output.write(result.stdout)
		return (True, output)

@dataclass
class CheckMatch(Command):
	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		success, diff_message = input.cmp(output)
		return (True, output) if success else (False, typing.cast(str, diff_message))


Test = typing.NamedTuple('Test', description=str, pipeline=tuple[Command, ...])


tests: tuple[Test, ...] = (
	Test(
		description = 'log->log symbol generation (sanity check)',
		pipeline=(
			ConvSym(
				input = Buffer(b'0: Start\n3FFFFF: End\n'),
				options = ('-input', 'log', '-output', 'log'),
			),
			CheckMatch(output=Buffer(b'0: Start\n3FFFFF: End\n'))
		),
	),
	Test(
		description = 'log->asm symbol generation (sanity check)',
		pipeline=(
			ConvSym(
				input = Buffer(b'0: Start\n3FFFFF: End\n'),
				options = ('-input', 'log', '-output', 'asm'),
			),
			CheckMatch(output=Buffer(b'Start:\tequ\t$0\nEnd:\tequ\t$3FFFFF\n'))
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
			CheckMatch(output=File('output-expected/logtest-simple.log'))
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
			CheckMatch(output=File('output-expected/logtest-advanced.log'))
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
			CheckMatch(output=File('output-expected/asm68k-lst-sample.log'))
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
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.log')),
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
		description = 'as_lst_legacy->deb2 symbol generation (Sonic 2 Xenowhirl Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2.lst'),
				output = File('output/sonic-2.deb2'),
				options = ('-input', 'as_lst_legacy'),
			),
			CheckMatch(output=File('output-expected/sonic-2.deb2')),
		),
	),
	Test(
		description = 'as_lst_legacy->deb2 symbol generation (Sonic 3K Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k.lst'),
				output = File('output/sonic-3k.deb2'),
				options = ('-input', 'as_lst_legacy'),
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
		description = 'as_lst_legacy->deb1 symbol generation (Sonic 2 Xenowhirl Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2.lst'),
				output = File('output/sonic-2.deb1'),
				options = ('-input', 'as_lst_legacy', '-output', 'deb1'),
			),
			CheckMatch(output=File('output-expected/sonic-2.deb1')),
		),
	),
	Test(
		description = 'as_lst_legacy->deb1 symbol generation (Sonic 3K Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k.lst'),
				output = File('output/sonic-3k.deb1'),
				options = ('-input', 'as_lst_legacy', '-output', 'deb1'),
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
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.sym.log')),
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
			CheckMatch(output=File('output-expected/sonic-1-hivebrain-2005.sym.asm')),
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
			CheckMatch(output=File('output-expected/sonic-1-git-2018.lst.log')),
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
			CheckMatch(output=File('output-expected/sonic-1-git-2018.sym.log')),
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
			CheckMatch(output=File('output-expected/sonic-1-git-2022-asm68k.lst.log')),
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
			CheckMatch(output=File('output-expected/sonic-1-git-2022-asm68k.sym.log')),
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
			CheckMatch(output=File('output-expected/sonic-1-git-2022-as.log')),
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
			CheckMatch(output=File('output-expected/sonic-2-git-2022.log')),
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
			CheckMatch(output=File('output-expected/sonic-3k-git-2022.log')),
		),
	),
	Test(
		description = 'as_lst_legacy->log symbol generation (Sonic 2 Git 2022 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-2-git-2022.lst'),
				output = File('output/sonic-2-git-2022.as_lst_legacy.log'),
				options = ('-in', 'as_lst_legacy', '-out', 'log')
			),
			CheckMatch(output=File('output-expected/sonic-2-git-2022.as_lst_legacy.log')),
		),
	),
	Test(
		description = 'as_lst_legacy->log symbol generation (Sonic 3K 2022 Disassembly)',
		pipeline=(
			ConvSym(
				input = File('input/sonic-3k-git-2022.lst'),
				output = File('output/sonic-3k-git-2022.as_lst_legacy.log'),
				options = ('-in', 'as_lst_legacy', '-out', 'log')
			),
			CheckMatch(output=File('output-expected/sonic-3k-git-2022.as_lst_legacy.log')),
		),
	),
)

def unarchiveDirectory(path: str):
	dir_path = Path(BASE_DIR, path)
	dir_archive_path = Path(BASE_DIR, path + '.tar.xz')

	if not dir_path.exists():
		print(f"Unpacking {str(dir_path)}...")
		with tarfile.open(dir_archive_path, 'r:xz') as f: f.extractall(dir_path)

	if not dir_path.is_dir():
		raise Exception(f'Expected {dir_path} to be a directory')


def main():
	unarchiveDirectory('input')
	unarchiveDirectory('output-expected')

	for test_id, test in enumerate(tests):
		print(f'[Test {test_id:d}] {test.description} ... ', flush=True, end='')

		pipeline_result: CommandResult = (True, Buffer())

		for command in test.pipeline:
			try:
				input, output = command.input or pipeline_result[1], command.output or Buffer()
				pipeline_result = command.execute(input, output)
				if pipeline_result[0] == False: break

			except Exception as e:
				raise e
				pipeline_result = (False, str(e)); break

		success, value = pipeline_result
		print("OK") if success else print(f'FAILED: {value}')


if __name__ == '__main__':
	main()
