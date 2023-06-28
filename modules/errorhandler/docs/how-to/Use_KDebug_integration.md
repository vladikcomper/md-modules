
# Using "KDebug" integration in MD Debugger

"KDebug" integration works in DEBUG builds and allows you to log messages, count cycles and break point in emulators that support it.

Currently, the only emulators that support KDebug are:
- Blastem-nightly;
- Gens KMod (outdated, not recommended).

Since Gens KMod is heavily out of date and Windows-only, **using Blastem-nightly is recommended instead.**

This guide briefly shows you how to set up both emulators to work with KDebug.

## Adding logging in your game

Before we actually set up one of the supported emulators, we need to actually make use of "KDebug" integration in the code, so we have something to tests.

The most commonly used (and overall useful) function is `KDebug.WriteLine`, which logs a formatted string to emulator's own console/window.

You can put the following anywhere in your code. Just make sure this code is reached when you test it:

```m68k
	KDebug.WriteLine "Hello, world!"
```

For a sligthly more practical example, you may also check "Log in-game events with `KDebug`" section of [Debugging Techniques](Debugging_techniques.md) guide.

For a full reference of the available `KDebug` macros, see the [Macros Reference](../Debug_macros.md).

## Setting up Blastem-nightly (recommended)

A newer, not yet official released, versions of Blastem support KDebug integrataion. They are still available as nightly builds, hence I use the name Blastem-nightly.

You can find all nightly builds here: https://www.retrodev.com/blastem/nightlies/. **But you need only the latest of them!** Find Blastem version 0.6.3-pre for your platform that was build recently.

At the time of writing, the following versions were-up-to date:
- Windows 64-bit: https://www.retrodev.com/blastem/nightlies/blastem-win64-0.6.3-pre-215c2afbe896.zip
- Linux 64-bit: https://www.retrodev.com/blastem/nightlies/blastem64-0.6.3-pre-215c2afbe896.tar.gz

**IMPORTANT!** To see the debug output, you need to launch Blastem-nightly from the terminal, so you can see its output.

## Setting up Gens KMod (not recommended)

> **Warning**
> 
> Kens KMod is a heavily outdated and inaccurate emulator. **Using it is not recommended.**

1. Start the emulator and enable debugging: "Option" > "Debug..." > "Active Development Features".

2. Open "CPU" > "Debug" > "Messages" to see the logs.


