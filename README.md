# MD-Modules

Various debugging modules and utilities for Sega Mega-Drive / Genesis ROMs.

## Repository structure

- **/utils** - the collection of cross-platform utilities used for/by debuggers, written in C++
  - **/utils/convsym** - a symbol data extraction utility;
  - **/utils/cbundle** - a custom pre-processor used to build debugger's bundles from the shared "cross-assembler" source files;
  - **/utils/blobtoasm** - a utility to render binary files in M68K assembly with additional tricks (e.g. offset-based expression injection);
  - **/utils/core** - base C++ classes used by utilities;

- **/modules** - the collection of debugging modules, written in M68K assembly
  - **/modules/errorhandler** - source code for Error Handler and Debugger blob
    - **/modules/errorhandler/bundles** - bundles source code that define debugger macros and integrate pre-compiled Error Handler blob into your projects.
  - **/modules/core** - source code for debugger's core, which includes Console subsystem (used by Error Handler)

## Pre-built utility binaries

For your convenience, this repository includes pre-built utility binaries, as those are used by modules. You can find them in the `modules/exec` directory.

Binaries are provided for the following platforms:
* **Windows 64-bit** (Windows 7 and above)
* **Linux 64-bit**

## Building utilities

### Dependencies

No dependencies are used rather than Standard C++ library.

### Compiler and architectures support

Builds have been tested and are expected to work with the following compilers: 
* __GCC__ versions 6 through 12
* __Clang__ verions 15

Other popular compilers are expected to work as well.

Generally, only x86_64 architecture is tested, but utils are expected to build for ARM and other targets.

### Building and testing

Utilities come with simple build scripts for Windows (`build.bat`) and Linux (`build.sh`).

Go to utility directory (e.g. `utils/convsym`) and run `build.bat` or `build.sh` dependening on your system.

To test executables in your environment, run `test.bat` or `test.sh`, depending on system.

## Building modules

### Dependencies

Debugging modules are built using ASM68K or AS assemblers (depending on their versions). Windows executables of these assemblers are included in the repository and used by build scripts.

Linux users are expected to have `wine` installed in order to invoke them.

### Building modules

Modules come with simple build scripts compile to them under Windows (`build.bat`) and Linux (`build.sh`).

Go to a module directory (e.g. `module/errorhandler`) and run `build.bat` or `build.sh` dependening on your system.
