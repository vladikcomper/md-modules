
# Working with Error Handler bundles

**IMPORTANT**

Do not change files in *bundle-\** folders directly!
These folders store auto-assembled and ready to install bundles targeting various assemblers/environments. Their contents are ignored by git and gets overwritten every time you run `build-bundles.bat`.

## Trivia

To keep maintaining different versions of bundles easier, they are mostly built from the "shared" pieces of code using `cbundle` utility (source code is available in the same repository).
Additionally, all the constants that refer to location inside Error Handler blob (`ErrorHandler.bin`) are formed automatically by `ConvSym` utility when the blob is built.

## Supported assemblers (environments)

Currently, the *Advanced Error Handler and Debugger 2.0* supports integration with the following assemblers:

* __ASM68K__ (bundle-asm68k)
* __The AS Macroassembler__ v.1.42 Bld 55 and above (bundle-as)
  - **WARNING!** This version has limited support for some features

## Notice regarding *-debug* bundles

Bundles with *-debug* postfix are used for internal testing only (see `_test` folder) and **shouldn't be used in your projects**.
They include the "debug" build of Error Handler blob (`ErrorHandler.Debug.bin`), which is slightly larger and slower version of debugger. It's compiled with `__DEBUG__` directive set to `1`, so some additional testing and diagnosis code is included in the blob, which is only useful for stability testing upon adding new features to the _core_ (files in `core` folder).
