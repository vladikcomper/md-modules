# MD-Modules

Various debugging modules and utilities for Sega Mega-Drive / Genesis ROMs.

## Repository structure

This repository includes modules for Mega-Drive projects (`modules/` directory) and various utilities (`utils/` directory) in one place, since most of them are tightly integrated or depend on each other. See below for the lists of modules and utilities.

### Modules

* [MD Debugger and Error Handler](modules/errorhandler) - also known as _The Advanced Error Handler and Debugger_, handles exceptions and helps to debug your Mega-Drive ROMs in any emulators and on the real hardware;
* [MD-Shell](modules/mdshell) - a stand-alone easy to use "assembly header" to run small programs as Mega-Drive ROMs, ncludes MD Debugger.

### Utilities

* [ConvSym](utils/convsym) _(C++20)_ - a symbol extraction and conversion utility;
* [CBundle](utils/cbundle) _(C++20)_ - a custom pre-processor used to build debugger's bundles from the shared "cross-assembler" source files;
* [BlobToAsm](utils/blobtoasm) _(Python 3.8+)_ - a utility to render binary files in M68K assembly with additional tricks (e.g. offset-based expression injection);

## Building from source code

This repository aims to be cross-platform, designed with Linux, Windows, MacOS (and other BSD systems) in mind. It makes extensive use of GNU-flavored Makefiles for both \*nix and Windows systems (see `Makefile` for \*nix and `Makefile.win` for Windows). Please read notes below to make sure you have all the prerequisites and your platform is fully supported.

### Dependencies

- *GNU Make* is required to build pretty much everything.

- **Utilities** require a *GCC* or *Clang* compiler with C++20 support and *Python 3.8* or newer.

- **Modules** fully depend on *utilities*, so they require all the dependencies listed above. Non-Windows systems also require *Wine* to run assemblers (they're 32-bit Windows executables).

### Windows

> [!NOTE]
>
> Only Windows 7 or newer is supported because of Python 3.8 and C++20 requirements. This guide targets Windows 10 or later; for Windows 7 you need alternative ways to install dependencies which are not covered here.

Make sure you have all the dependencies. This example uses Chocolatey to automate dependency installation, but you may choose any other option that works for you:

```sh
choco install mingw python3 make
```

Once dependencies are installed, build process is the same as on Unix-like systems. In Command Prompt (`cmd.exe`), use one of the following commands:

```sh
make
# or separately:
make utils
make modules
```

> [!NOTE]
>
> You must have `make.exe`, `gcc.exe`, `python3.exe` and a few others available via `PATH` environment variable for all commands to work properly. Chocolatey and other package managers usually take care of that, but if you get "XXX is not recognized as an internal or external command ..." errors, then your shell cannot locate those executables, so you have to find their installation paths and append to the `PATH` variable manually.

If you want to invoke `make` from individual directories however (not root), be sure to use `make -f Makefile.win` instead (the root Makefile does it automatically).

### Linux

Make sure you have the necessary dependencies using your package manager (this following example uses `apt` under Debian/Ubuntu):

```sh
apt install g++ make python3 wine
```

To build everything, use one of the following commands:

```sh
make
# or separately:
make utils
make modules
```

### FreeBSD

Make sure you have the necessary dependencies:

```sh
pkg install gmake python3 wine
```

> [!NOTE]\
> If you're running a 64-bit system, you'll likely also need a 32-bit installation of Wine. As of FreeBSD 13, the following script may automate the process:
>
> ```sh
> /usr/local/share/wine/pkg32.sh install wine
> ```
> 
> Consult your distribution's manuals for more information.

Please note that you specifically need to use GNU-Make instead of BSD-flavoured Make everywhere:

```sh
gmake
# or separately:
gmake utils
gmake modules
```

### MacOS

> [!WARNING]\
> Since MacOS Catalina 10.15, 32-bit software is no longer supported. You may not be able to build *Modules* which require 32-bit Wine. The only proper workaround (at the time of writing) is to use a VM.

Make sure you have Wine:

```sh
brew tap homebrew/cask-versions
brew install --cask --no-quarantine wine-stable
```

To build everything, use one of the following commands:

```sh
make
# or separately:
make utils
make modules
```
