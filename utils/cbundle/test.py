#!/usr/bin/env python3
from dataclasses import dataclass
from typing import cast
from pathlib import Path
import subprocess

import sys

sys.path.append('../core-py')
from test_framework import Test, Command, CommandResult, DataSource, File, CheckMatch, Buffer, Void, archiveDirectory, unarchiveDirectory, getUsedFilesList, runTests

BASE_DIR = '_test'

@dataclass
class CBundle(Command):
	options: 'tuple[str, ...]' = ()

	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		use_stdin = not isinstance(input, File)
		use_stdout = not isinstance(output, File)

		# Launch CBundle
		args = ['./cbundle', '-', *self.options]
		args[1] = '-' if use_stdin else str(cast(File, input).getPath())
		if not isinstance(output, Void):
			args += ['-out', '-' if use_stdout else str(cast(File, output).getPath())]

		result = subprocess.run(args, input=None if isinstance(input, File) else input.read(), text=False, capture_output=True)

		# Collect output
		if result.returncode != 0: return (False, f'CBundle returned non-zero exit code (stderr="{result.stderr}")')
		if use_stdout: output.write(result.stdout)
		return (True, output)

tests: 'tuple[Test, ...]' = (
	Test(
		description = 'One static line',
		pipeline=(
			CBundle(
				input = Buffer(b'Hello world!\n'),
			),
			CheckMatch(
				output=Buffer(b'Hello world!\n'),
				text=True
			),
		),
	),
	Test(
		description = 'Undefined symbol test',
		pipeline=(
			CBundle(
				input = Buffer(b'#ifdef SYMBOL\nSYMBOL IS DEFINED\n#endif\n'),
			),
			CheckMatch(
				output=Buffer(b''),
				text=True
			),
		),
	),
	Test(
		description = 'Pre-defined symbol test',
		pipeline=(
			CBundle(
				input = Buffer(b'#ifdef SYMBOL\nSYMBOL IS DEFINED\n#endif\n'),
				options=('-def', 'SYMBOL'),
			),
			CheckMatch(
				output=Buffer(b'SYMBOL IS DEFINED\n'),
				text=True
			),
		),
	),
	Test(
		description = 'Several pre-defined symbols',
		pipeline=(
			CBundle(
				input = Buffer(b'#ifdef SYMBOL1\nSYMBOL1 IS DEFINED\n#endif\n#ifdef SYMBOL2\nSYMBOL2 IS DEFINED\n#endif\n'),
				options=('-def', 'SYMBOL1', '-def', 'SYMBOL2'),
			),
			CheckMatch(
				output=Buffer(b'SYMBOL1 IS DEFINED\nSYMBOL2 IS DEFINED\n'),
				text=True
			),
		),
	),
	Test(
		description = 'Generating a sample bundle',
		pipeline=(
			CBundle(
				input = File('input/sample.cbundle'),
				options=('-cwd', BASE_DIR)
			),
			CheckMatch(
				input=File(f'{BASE_DIR}/output/sample-file-1.txt'),
				output=File(f'{BASE_DIR}/output-expected/sample-file-1.txt'),
				text=True
			),
			CheckMatch(
				input=File(f'{BASE_DIR}/output/sample-file-2.txt'),
				output=File(f'{BASE_DIR}/output-expected/sample-file-2.txt'),
				text=True
			),
		),
	),
)

def main():
	success = runTests(tests)

	if not success:
		exit(1)

if __name__ == '__main__':
	main()
