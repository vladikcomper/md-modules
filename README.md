# MD-Modules

Various debugging modules and utilities for Sega Mega-Drive / Genesis ROMs.

## Repository structure

- **/utils** - the collection of cross-platform utilities used for/by debuggers, written in C++
  - **/utils/convsym** - source code for *ConvSym*, the symbol data extraction utility
  - **/utils/cbundle** - source code for *CBundle*, custom pre-processor used to build debugger's bundles from the shared "cross-assembler" source files
  - **/utils/core** - base C++ classes used by utilities

- **/modules** - the collection of debugging modules, written in M68K assembly
  - **/modules/errorhandler** - source code for Error Handler and Debugger blob
    - **/modules/errorhandler/bundles** - bundles source code that define debugger macros and integrate pre-compiled Error Handler blob into your projects.
  - **/modules/core** - source code for debugger's core, which includes Console subsystem (used by Error Handler)
    
## Building utilities

Utilities come with simple build scripts for Windows (`build.bat`) and Linux (`build.sh`).

> **NOTICE**: While Windows build scripts are expected to work, they have been untested after last updates to the building system.

These scripts require that you have GCC installed on your system. However, source code doesn't rely on third party libraries or compiler-specific features, so other compilers besides GCC should work as well.

Source codes are not tied to any particular IDE, hence there are no pre-configured project files. If you want to use IDE of your choice, you'll have to configure project files on your own.

### Supported platforms

Utilities code is cross-platform and can be compiled on Windows, Linux and MacOS platforms. However, only Windows versions are "officially" released now (see notes below).

For your convinience, repository comes with pre-compiled binaries of all the utilities for 64-bit Windows and Linux.

- **Windows binaries** were fully supported until mid 2020. However, they currently aren't updated anymore. Be warned that the provided Windows binaries may not pass some of the tests correctly.
- **Linux binaries** are fully tested and supported after 2020. You should be able to compile and test them with any version of GCC that supports C++11.
- **MacOS binaries** are also possible, I believe, but I do not have access to this platform.

## Building modules

Debugging modules are built using ASM68K or AS assemblers (depending on their versions). Windows executables of these assemblers are included in the repository and used by build scripts.

Unlike utilities which are compiled with cross-platform compiler, GCC, building tools used here mostly target Windows. For Linux users, `wine` is required to use them.
