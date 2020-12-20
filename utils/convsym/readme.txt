ConvSym utility version 2.5.2
2016-2018, 2020, vladikcomper

Command line arguments:
  convsym [input_file] [output_file] <options>

Available options:
  -input
    Selects input file format. Currently supported format specifiers: asm68k_sym, asm68k_lst, as_lst
    Default value is: asm68k_sym

  -output
    Selects output file format. Currently supported format specifiers: asm, deb1, deb2, log
    Default value is: deb2

  -base [offset]
    Sets the base offset for the input data: it is subtracted from every symbol's offset found in [input_file] to form the final offset. Default value is: 0

  -range [bottom] [upper]
    Determines the range for offsets allowed in a final symbol file (after subtraction of the base offset), default is: 0 3FFFFF

  -a
    Appending mode: symbol data is appended to the end of the [output_file], not overwritten

  -org [offset]
    Specifies offset in the output file to place generated debug information at. It is not set by default.

  -ref [offset]
    Specifies offset in the output file where 32-bit Big Endian offset pointing to the debug information data will be written. It is not set by default.

  -inopt [options]
    Additional options for the input parser. There parameters are specific to the selected -input format.

  -outopt [options]
    Additional options for the output parser. There parameters are specific to the selected -output format.

  -toupper
    Convert all symbols names to uppercase.

  -tolower
    Convert all symbols names to lowercase.

  -filter [regex]
    Enables filtering of the symbol list fetched from the [input_file] based on a regular expression.

  -exclude
    If set, filter works in "exclude mode": all labels that DO match the -filter regex are removed from the list, everything that DO NOT match the regex is removed if this flag is not set .
