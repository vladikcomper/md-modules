
# Using KDebug integration in MD Debugger

![KDebug integration](../.images/eh_kdebug.png)

MD Debugger version 2.5 and above supports "KDebug" integration, which allows you to log messages, count cycles and add breakpoints in emulators that support it. This is achieved by using `KDebug` macros (e.g. `KDebug.WriteLine`, `KDebug.BreakPoint`). Please note that these macros only have effect in DEBUG builds (when `__DEBUG__` equate is set).

Currently, the only emulators that support KDebug are:
- Blastem-nightly (recommended);
- Clownmdemu v.0.8 and above (logging only);
- Gens KMod (outdated, not recommended).

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

Newer, not yet officially released versions of Blastem support KDebug integration. They are available as nightly builds, hence why I used the name "Blastem-nightly".

You can find all nightly builds here: https://www.retrodev.com/blastem/nightlies/. Make sure to get Blastem version 0.6.3-pre for your platform that was build recently.

At the time of writing, the following versions were up-to date:
- Windows 64-bit: https://www.retrodev.com/blastem/nightlies/blastem-win64-0.6.3-pre-f973651b48d7.zip
- Linux 64-bit: https://www.retrodev.com/blastem/nightlies/blastem64-0.6.3-pre-f973651b48d7.tar.gz

### Viewing debug messages

Once your ROM any KDebug log message, a terminal window should appear with the logged message displayed.

On Linux though, the output in the terminal window can be delayed and only flushed in chunks (as of tested builds), so it's recommended to run Blastem from the terminal instead (this way KDebug logs are redirected to standard output):

1. Open Terminal and type in path to the `blastem` executable (you may add it to your `PATH` for easier access);
2. You will see debug messages in the very same terminal.

If you have issues seing Blastem's terminal output on your OS, conside the following:

1. Press the `u` key to pause the game and toggle debugger;
2. You should now emulator's console and all the messages up to this point;
3. Since you've paused the game by toggling the debugger, type `c` in the console and press `Enter` to continue;
4. The emulator's console will still be open in a separate window and you should now see debug messages properly.

![Blastem console on Windows](../.images/blastem-win-console.png)

## Setting up Clownmdemu

Clownmdemu has partial support for KDebug integration since v.0.8. It only allows for KDebug logging (meaning only `KDebug.WriteLine` macros work).

Setting it up is quite easy: open **Debugging > Log** in the menu and check "Enable Logging". KDebug logging will only be enabled after it, so if you wanted any logging during ROM's boot, you may want to soft-reset.

## Setting up Gens KMod (not recommended)

> [!WARNING]
> 
> Kens KMod is a heavily outdated and inaccurate emulator. **Using it is not recommended.**

1. Start the emulator and enable debugging: "Option" > "Debug..." > "Active Development Features".

   ![Gens KMod Debug menu](../.images/gens-kmod_menu.png)

   ![Gens KMod Debug options](../.images/gens-kmod_debug.png)

2. Open "CPU" > "Debug" > "Messages" to see the logs.

   ![Gens KMod Debug Messages](../.images/gens-kmod_messages.png)
