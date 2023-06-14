# MD-Modules

Various debugging modules and utilities for Sega Mega-Drive / Genesis ROMs.

## Repository structure

This repository includes modules for Mega-Drive projects (`modules/` directory) and various utilities (`utils/` directory) in one place, since most of them are tightly integrated or depend on each other. See below for the lists of modules and utilities.

### Modules

* [Error Handler](modules/errorhandler) - the Advanced Error Handler and Debugger for handling exceptions and debugging your Mega-Drive ROMs;
* [MD-Shell](modules/mdshell) - a stand-alone easy to use "assembly header" to run small programs as Mega-Drive ROMs.

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

### Linux (Ubuntu/Debian)

Make sure you have the necessary dependencies:

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

> **Note**
>
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

Make sure you have Wine:

```sh
brew tap homebrew/cask-versions
brew install --cask --no-quarantine wine-stable
```

> **Warning**
>
> Since MacOS Catalina 10.15, 32-bit software is no longer supported. You may not be able to build *Modules* which require 32-bit Wine.

To build everything, use one of the following commands:

```sh
make
# or separately:
make utils
make modules
```

### Windows

Make sure you have all the dependencies. This examples uses Chocolatey to automate dependency installation, but you may choose any other option that works for you:

```sh
choco install mingw python3 make
```

On Windows, you must always use `Makefile.win` instead of `Makefile`, so you have to pass `-f Makefile.win` option to every invocation of `make`:

```sh
make -f Makefile.win
# or separately:
make -f Makefile.win utils
make -f Makefile.win modules
```
