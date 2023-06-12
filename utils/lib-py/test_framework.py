#!/usr/bin/env python3
from typing import cast, Union, List, Literal, NamedTuple
from dataclasses import dataclass
from pathlib import Path
import platform
import filecmp
import tarfile

CompareResult = Union['tuple[Literal[True], None]', 'tuple[Literal[False], str]']

class DataSource:
	def read(self) -> bytes: raise Exception('Not implemented')
	def write(self, data: bytes): raise Exception('Not implemented')
	def cmp(self, other, textMode=False) -> CompareResult:
		data1, data2 = self.read(), cast(DataSource, other).read()

		# For Windows and MacOS in text mode, we have to convert newlines, since all examples store Linux newlines
		if textMode and platform.system() in ('Windows', 'Darwin'):
			data1 = data1.replace(b'\r\n', b'\n').replace(b'\r', b'\n')
			data2 = data2.replace(b'\r\n', b'\n').replace(b'\r', b'\n')

		if data1 != data2:
			return (False, f'Expected "{data2}", got "{data1}"') if len(data1) + len(data2) < 512 else (False, "Expected data to match")
		return (True, None)

@dataclass
class File(DataSource):
	path: str
	def read(self) -> bytes: return self.getPath().read_bytes()
	def write(self, data: bytes): return self.getPath().write_bytes(data)
	def getPath(self) -> Path: return Path(getBaseDir(), self.path)
	def cmp(self, other, textMode=False) -> CompareResult:
		# If both data sources to compare are files, we can use `filecmp.cmp` as an optimization.
		# But this is only applicable in non-text mode OR with text mode on Linux, since all example use Linux newlines
		if isinstance(other, File) and ((not textMode) or (textMode and platform.system() == 'Linux')):
			return (True, None) if filecmp.cmp(self.getPath(), other.getPath()) else (False, f'Expected "{self.getPath()}" to match "{other.getPath()}"')
		return super().cmp(other, textMode)

@dataclass
class Buffer(DataSource):
	value: bytes = bytes()
	def read(self) -> bytes: return self.value
	def write(self, data: bytes): self.value = data

@dataclass
class Void(DataSource):
	def read(self) -> bytes: return bytes()
	def write(self, data: bytes): pass


CommandResult = Union['tuple[Literal[True], DataSource]', 'tuple[Literal[False], str]']

@dataclass()
class Command:
	output: Union[DataSource, None] = None
	input: Union[DataSource, None] = None

	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		return (False, 'Unable to execute command: not implemented')

@dataclass
class CheckMatch(Command):
	text: bool = False

	def execute(self, input: DataSource, output: DataSource) -> CommandResult:
		success, diff_message = input.cmp(output, self.text)
		return (True, output) if success else (False, cast(str, diff_message))


Test = NamedTuple('Test', description=str, pipeline='tuple[Command, ...]')


def unarchiveDirectory(path: str, *, skipIfExists=True):
	dir_path = Path(getBaseDir(), path)
	dir_archive_path = Path(getBaseDir(), path + '.tar.xz')
	if dir_path.exists() and dir_path.is_dir() and skipIfExists:
		return

	print(f"Unpacking {str(dir_archive_path)}...")
	with tarfile.open(dir_archive_path, 'r:xz') as f: f.extractall(getBaseDir())


def archiveDirectory(path: str):
	dir_path = Path(getBaseDir(), path)
	dir_archive_path = Path(getBaseDir(), path + '.tar.xz')

	if not dir_path.exists():
		raise Exception(f'Directory {path} wasn\'t unpacked.')
	if dir_archive_path.exists():
		dir_archive_path.unlink()

	print(f"Archiving {str(dir_path)} -> {str(dir_archive_path)}")
	with tarfile.open(dir_archive_path, 'x:xz', preset=9) as f:
		f.add(dir_path, arcname=path)


def getUsedFilesList(tests: 'tuple[Test, ...]') -> List[str]:
	file_sources = [
		source
		for test in tests for command in test.pipeline for source in (command.input, command.output)
		if isinstance(source, File)
	]
	file_paths = [ str(source.getPath()) for source in file_sources ]
	return file_paths


def runTests(tests: 'tuple[Test, ...]') -> bool:
	has_failed_tests = False

	for test_id, test in enumerate(tests):
		print(f'[Test {test_id:d}] {test.description} ... ', flush=True, end='')

		pipeline_result: CommandResult = (True, Buffer())

		for command in test.pipeline:
			try:
				input, output = command.input or pipeline_result[1], command.output or Buffer()
				pipeline_result = command.execute(input, output)
				if pipeline_result[0] == False: break

			except Exception as e:
				pipeline_result = (False, str(e)); break

		success, value = pipeline_result
		if success:
			print("OK") 
		else:
			print(f'FAILED: {value}')
			has_failed_tests = True

	return not has_failed_tests

_BASE_DIR_: str = '.'

def setBaseDir(base_dir: str):
	global _BASE_DIR_
	_BASE_DIR_ = base_dir


def getBaseDir() -> str:
	global _BASE_DIR_
	return _BASE_DIR_
