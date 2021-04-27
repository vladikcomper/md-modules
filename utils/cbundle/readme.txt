CBundle utility version 1.6
2017-2018, 2020-2021, vladikcomper

Command line arguments:
  cbundle [script_file_path|-]

NOTICE: Using "-" as a script file path redirects input to stdin.

List of supported directives:

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
