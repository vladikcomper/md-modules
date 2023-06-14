
# Building Error Handler

Make sure you're in the right directory:

```sh
cd modules/errorhandler/
```

Use the appropriate GNU Make invocation depending on your system:

- **Linux/MacOS**: `make`
- **FreeBSD**: `gmake`
- **Windows**: `make -f Makefile.win`

Bundles will be generated in `build/modules/errorhandler`.

## Testing

Various tests are also provided in form of compilable Mega-Drive ROMs to make sure MD-Shell is stable and usable.

To build tests, use the appropriate GNU Make invocation depending on your system:

- **Linux/MacOS**: `make tests`
- **FreeBSD**: `gmake tests`
- **Windows**: `make -f Makefile.win tests`

ROMs will be generated in `build/modules/errorhandler/tests`. Note that **this won't actually test anything yet**! You need to manually run ROMs in your favorite Sega Mega-Drive emulator to see the results.
