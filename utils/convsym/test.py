#!/usr/bin/env python3
from enum import Enum
import typing
import subprocess
import filecmp
import gzip

from dataclasses import dataclass

class SourceType(Enum):
	File = 1
	CompressedFile = 2
	CaptureStdout = 3
	Inline = 4

DataSource = typing.NamedTuple('DataSource', type=SourceType, value=any)

File = lambda path: DataSource(type=SourceType.File, value=f'_test/{path}')
CompressedFile = lambda path: DataSource(type=SourceType.CompressedFile, value=f'_test/{path}')
CaptureStdout = lambda: DataSource(type=SourceType.CaptureStdout, value=None)
Inline = lambda value: DataSource(type=SourceType.Inline, value=value)

class Process:
	def execute(self, outputsSoFar: tuple[DataSource, ...]) -> tuple[bool, str | DataSource]:
		return (False, 'Unable to execute process: method not implemented')


@dataclass
class ConvSym(Process):
	input: DataSource
	output: DataSource
	options: tuple[str, ...]
	text: bool = False

	def execute(self, outputsSoFar: tuple[DataSource, ...]) -> tuple[bool, str | DataSource]:
		# Prepare ConvSym arguments
		args = ['./convsym', '-', '-', *self.options]
		args[1] = '-' if self.input.type != SourceType.File else self.input.value
		args[2] = '-' if self.output.type != SourceType.File else self.output.value

		# Execute ConvSym
		input = None if self.input.type == SourceType.File else readFromDataSource(self.input)
		result = subprocess.run(args, input=input, text=self.text, capture_output=True)

		# Collect output
		if result.returncode != 0:
			return (False, f'ConvSym returned non-zero exit code (stderr="{result.stderr}")')
		output = self.output if self.output.type != SourceType.CaptureStdout else Inline(result.stdout)
		return (True, output)


@dataclass
class ExpectOutputToMatch(Process):
	expectedOutput: DataSource | None = None
	actualOutput: DataSource | None = None

	def execute(self, outputsSoFar: tuple[DataSource, ...]) -> tuple[bool, str | DataSource]:
		actualOutput = outputsSoFar[-1] if self.actualOutput is None else self.actualOutput
		expectedOutput = outputsSoFar[-2] if self.expectedOutput is None else self.expectedOutput

		if actualOutput.type == SourceType.File and expectedOutput.type == SourceType.File:
			if filecmp.cmp(actualOutput.value, expectedOutput.value):
				return (True, expectedOutput)
			else:
				return (False, f'Expected "{actualOutput.value}" to match "{expectedOutput.value}"')

		data1 = typing.cast(bytes, readFromDataSource(actualOutput))
		data2 = typing.cast(bytes, readFromDataSource(expectedOutput))

		if data1 != data2:
			return (False, 'Expected data to match')

		return (True, expectedOutput)


@dataclass
class SymbolTableDiff(Process):
	output: DataSource
	input1: DataSource | None = None
	input2: DataSource | None = None

	def execute(self, outputsSoFar: tuple[DataSource, ...]) -> tuple[bool, str | DataSource]:
		table1 = typing.cast(str, readFromDataSource(outputsSoFar[-2] if self.input1 is None else self.input1, text=True)).split('\n')
		table2 = typing.cast(str, readFromDataSource(outputsSoFar[-1] if self.input2 is None else self.input2, text=True)).split('\n')

		data = '\n'.join(set(table1).symmetric_difference(set(table2)))

		writeToDataSource(self.output, data, text=True)

		return (True, self.output)


Test = typing.NamedTuple('Test', description=str, runs=tuple[Process, ...])


tests: tuple[Test, ...] = (
	Test(
		description = 'log->log symbol generation (logtest.in.log)',
		runs=(
			ConvSym(
				input = File('logtest.in.log'),
				output = File('logtest.out.log'),
				options = ('-input', 'log', '-output', 'log', '-inopt', '/separator=: /useDecimal+'),
			),
			ExpectOutputToMatch(File('logtest.out.log.model'))
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (test.lst)',
		runs=(
			ConvSym(
				input = File('test.lst'),
				output = File('test.log'),
				options = ('-input', 'asm68k_lst', '-output', 'log'),
			),
			ExpectOutputToMatch(File('test.log.model'))
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (Sonic 1 Hivebrain Disassembly)',
		runs=(
			ConvSym(
				input = CompressedFile('s1built.lst.gz'),
				output = File('s1built.log'),
				options = ('-input', 'asm68k_lst', '-output', 'log', '-inopt', '/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+'),
			),
			ExpectOutputToMatch(File('s1built.log.model')),
		),
	),
	Test(
		description = 'asm68k_sym->deb2 symbol generation (Sonic 1 Hivebrain Disassembly)',
		runs=(
			ConvSym(
				input = File('sonic1.sym'),
				output = File('sonic1.deb2'),
				options = ('-input', 'asm68k_sym'),
			),
			ExpectOutputToMatch(File('sonic1.deb2.model')),
		),
	),
	Test(
		description = 'as_lst_legacy->deb2 symbol generation (Sonic 2 Disassembly)',
		runs=(
			ConvSym(
				input = CompressedFile('sonic2.lst.gz'),
				output = File('sonic2.deb2'),
				options = ('-input', 'as_lst_legacy'),
			),
			ExpectOutputToMatch(File('sonic2.deb2.model')),
		),
	),
	Test(
		description = 'as_lst_legacy->deb2 symbol generation (Sonic 3K Disassembly)',
		runs=(
			ConvSym(
				input = CompressedFile('sonic3k.lst.gz'),
				output = File('sonic3k.deb2'),
				options = ('-input', 'as_lst_legacy'),
			),
			ExpectOutputToMatch(File('sonic3k.deb2.model')),
		),
	),
	Test(
		description = 'asm68k_sym->deb1 symbol generation (Sonic 1 Hivebrain Disassembly)',
		runs=(
			ConvSym(
				input = File('sonic1.sym'),
				output = File('sonic1.deb1'),
				options = ('-input', 'asm68k_sym', '-output', 'deb1'),
			),
			ExpectOutputToMatch(File('sonic1.deb1.model')),
		),
	),
	Test(
		description = 'as_lst_legacy->deb1 symbol generation (Sonic 2 Disassembly)',
		runs=(
			ConvSym(
				input = CompressedFile('sonic2.lst.gz'),
				output = File('sonic2.deb1'),
				options = ('-input', 'as_lst_legacy', '-output', 'deb1'),
			),
			ExpectOutputToMatch(File('sonic2.deb1.model')),
		),
	),
	Test(
		description = 'as_lst_legacy->deb1 symbol generation (Sonic 3K Disassembly)',
		runs=(
			ConvSym(
				input = CompressedFile('sonic3k.lst.gz'),
				output = File('sonic3k.deb1'),
				options = ('-input', 'as_lst_legacy', '-output', 'deb1'),
			),
			ExpectOutputToMatch(File('sonic3k.deb1.model')),
		),
	),
	Test(
		description = 'asm68k_sym->log symbol generation (Sonic 1 Hivebrain Disassembly)',
		runs=(
			ConvSym(
				input = File('sonic1.sym'),
				output = File('sonic1.sym.log'),
				options = ('-input', 'asm68k_sym', '-output', 'log'),
			),
			ExpectOutputToMatch(File('sonic1.sym.log.model')),
		),
	),
	Test(
		description = 'asm68k_sym->asm symbol generation (Sonic 1 Hivebrain Disassembly)',
		runs=(
			ConvSym(
				input = File('sonic1.sym'),
				output = File('sonic1.sym.asm'),
				options = ('-input', 'asm68k_sym', '-output', 'asm'),
			),
			ExpectOutputToMatch(File('sonic1.sym.asm.model')),
		),
	),
	Test(
		description = 'asm68k_lst->log symbol generation (Sonic 1 Git Disassembly)',
		runs=(
			ConvSym(
				input = CompressedFile('sonic1git.lst.gz'),
				output = File('sonic1git.lst.log'),
				options = ('-in', 'asm68k_lst', '-out', 'log', '-tolower', '-inopt', '/localSign=@ /localJoin=. /ignoreMacroExp- /ignoreMacroDefs- /addMacrosAsOpcodes+ /processLocals+')
			),
			ExpectOutputToMatch(File('sonic1git.lst.log.model')),
		),
	),
	Test(
		description = 'asm68k_sym->log symbol generation (Sonic 1 Git Disassembly)',
		runs=(
			ConvSym(
				input = File('sonic1git.sym'),
				output = File('sonic1git.sym.log'),
				options = ('-in', 'asm68k_sym', '-out', 'log', '-tolower', '-inopt', '/localSign=@ /localJoin=. /processLocals+'),
			),
			ExpectOutputToMatch(File('sonic1git.sym.log.model')),
		),
	),
	Test(
		description = 'asm68k_sym<->asm68k_lst symbols match (Sonic 1 Hivebrain Disassembly)',
		runs = (
			ConvSym(
				input = CompressedFile('s1built.lst.gz'),
				output = File('sonic1.asm68k_lst.deb2'),
				options = ('-input', 'asm68k_lst', '-output', 'deb2', '-tolower', '-inopt', '/processLocals-'),
			),
			ConvSym(
				input = File('sonic1.sym'),
				output = File('sonic1.asm68k_sym.deb2'),
				options = ('-input', 'asm68k_sym', '-output', 'deb2', '-tolower'),
			),
			ExpectOutputToMatch(File('sonic1.asm68k_lst.deb2')),
		),
	),
	Test(
		description = 'asm68k_sym<->asm68k_lst symbols diff (Sonic 1 Git Disassembly)',
		runs = (
			ConvSym(
				input = CompressedFile('sonic1git.lst.gz'),
				output = CaptureStdout(),
				options = ('-input', 'asm68k_lst', '-output', 'log', '-tolower'),
			),
			ConvSym(
				input = File('sonic1git.sym'),
				output = CaptureStdout(),
				options = ('-input', 'asm68k_sym', '-output', 'log', '-tolower'),
			),
			SymbolTableDiff(
				output = File('sonic1git.symbol_diff.log')
			)
		),
	),
)


def readFromDataSource(source: DataSource, *, text=False) -> str | bytes:
	if source.type == SourceType.CompressedFile:
		with gzip.open(source.value, 'r' if text else 'rb') as f:
			return f.read()
	if source.type == SourceType.File:
		with open(source.value, 'r' if text else 'rb') as f:
			return f.read()
	if source.type == SourceType.Inline:
		if text:
			return source.value if isinstance(source.value, str) else source.value.decode('utf-8')
		else:
			return source.value if isinstance(source.value, bytes) else source.value.encode('utf-8')
	raise Exception('Unable to read from data source')


def writeToDataSource(source: DataSource, data: str | bytes, *, text=False):
	if source.type == SourceType.CaptureStdout:
		return Inline(data)
	elif source.type == SourceType.File:
		with open(source.value, 'w' if text else 'wb') as f:
			f.write(data)
	elif source.type == SourceType.CompressedFile:
		with gzip.open(source.value, 'w' if text else 'wb') as f:
			f.write(typing.cast(bytes, data))
	else:
		raise Exception('Unable to write to data source')


def main():
	for test_id, test in enumerate(tests):
		print(f'[Test {test_id:d}] {test.description} ... ', flush=True, end='')

		outputs = []

		for run in test.runs:
			try:
				success, value = run.execute(outputs)

				if not success:
					print(f'FAILED: {value}')
					break
				else:
					outputs.append(value)

			except Exception as e:
				print(f'RUNTIME ERROR: {e}')
				break

		print("OK")


if __name__ == '__main__':
	main()
