# MD-Modules

Various debugging modules and utilities for Sega Mega-Drive / Genesis ROMs.

## Repository structure

This repository includes modules for Mega-Drive projects (`modules/` directory) and various utilities (`utils/` directory) in one place, since most of them are tightly integrated or depend on each other. See below for the lists of modules and utilities.

### Modules

* [Error Handler](modules/errorhandler) - source code for the Advanced Error Handler and Debugger for Mega-Drive ROMs;
  * [Error Handler/bundles](modules/errorhandler/bundles) - bundles source code that define debugger macros and integrate pre-compiled Error Handler blob into your projects;
* [MD-Shell](modules/mdshell) - a stand-alone easy to use "assembly header" to run small programs as Mega-Drive ROMs.

### Utilities

* [ConvSym](utils/convsym) _(C++20)_ - a symbol extraction and conversion utility;
* [CBundle](utils/cbundle) _(C++20)_ - a custom pre-processor used to build debugger's bundles from the shared "cross-assembler" source files;
* [BlobToAsm](utils/blobtoasm) _(Python 3.8+)_ - a utility to render binary files in M68K assembly with additional tricks (e.g. offset-based expression injection);

## Pre-built utility binaries

For your convenience, this repository includes pre-built utility binaries, as those are used by modules. You can find them in the `modules/exec` directory.

Binaries are provided for the following platforms:
* **Windows 64-bit** (Windows 7 and above)
* **Linux 64-bit**
* **MacOS 64-bit** (built on MacOS Big Sur)

## Building utilities

### Dependencies

No dependencies are used rather than Standard C++ library.

### Compiler and architectures support

Builds have been tested and are expected to work with the following compilers: 
* __GCC__ versions 6 through 12
* __Clang__ version 15

Other popular compilers are expected to work as well.

Generally, only x86_64 architecture is tested, but utils are expected to build for ARM and other targets.

### Building and testing

Utilities come with simple build scripts for Windows (`build.bat`) and Linux/MacOS (`build.sh`).

Go to utility directory (e.g. `utils/convsym`) and run `build.bat` or `build.sh` dependening on your system.

To test executables in your environment, run `test.py` (Python 3.8+ is required).

## Building modules

### Dependencies

Debugging modules are built using ASM68K or AS assemblers (depending on their versions). Windows executables of these assemblers are included in the repository and used by build scripts.

Linux users are expected to have `wine` installed in order to invoke them.

### Building modules

Modules come with simple build scripts compile to them under Windows (`build.bat`) and Linux (`build.sh`).

Go to a module directory (e.g. `module/errorhandler`) and run `build.bat` or `build.sh` dependening on your system.
