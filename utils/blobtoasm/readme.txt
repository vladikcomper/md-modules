usage: blobtoasm.py [-h] [-t SYMBOLTABLE] [-m INJECTIONMAP]
                    [-s {long,word,byte,l,w,b}] [-l UNITSPERLINE]
                    blob outfile

Renders binary files in M68K assembly.

positional arguments:
  blob
  outfile

options:
  -h, --help            show this help message and exit
  -t SYMBOLTABLE, --symbolTable SYMBOLTABLE
                        Path to a symbol table in log format, which may
                        include control symbols for the conversion, e.g.
                        __blob_start, __blob_end
  -m INJECTIONMAP, --injectionMap INJECTIONMAP
                        Path to injection map, which tells how to inject
                        symbols marked as __inject_* in symbol table
  -s {long,word,byte,l,w,b}, --unitSize {long,word,byte,l,w,b}
                        Specifies the default unit size when rendering blob;
                        this will select between dc.l, dc.w and dc.b
  -l UNITSPERLINE, --unitsPerLine UNITSPERLINE
                        Specifies number of units per line
