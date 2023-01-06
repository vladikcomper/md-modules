CBundle utility version 2.0
2017-2023, vladikcomper

Command line arguments:
  cbundle [script_file_path|-] [OPTIONS]

NOTICE: Using "-" as a script file path redirects input to stdin.

OPTIONS:
  -out [output_file_path|-]
    If set, writes output to the given path, unless overriden by #file directive. Using - will redirect to stdout.

  -def [symbol]
    Pre-defines a symbol with the given, equivalent to #def [symbol] directive. To specify several symbols, repeat -def [symbol] as many times as needed.

  -cwd [dir]
    If set, changes current working directory to [dir]. Path can be relative.

  -debug
    Enable debug output.

SUPPORTED DIRECTIVES:

  #define <Symbol>
    Defines a symbol.

  #undef <Symbol>
    Removes a symbol from defined symbols list.

  #include <FilePath>
    Opens the specified file and executes its directives.

  #file <FilePath>
    Creates or rewrites a file, directs all the output to this file.

  #endf
    Finishes writing to previously opened file.

  #ifdef <Symbol>
    Enters IF-block if symbol was defined previously.

  #ifndef <Symbol>
    Enters IF-block if symbol wasn't defined previously.

  #else
    Enters ELSE-block if the IF-block's condition wasn't met.

  #endif
    Ends IF-ELSE-block.
