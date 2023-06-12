
/* ------------------------------------------------------------ *
 * Bundle Compilation utility v.2.0.1							*
 *																*
 * Main definitions file										*
 * (c) 2017-2023, Vladikcomper									*
 * ------------------------------------------------------------	*/

// Standard C-libraries
#include <cstdio>			// for I/O operations and file accesses
#include <cstdint>			// for uint8_t, uint16_t, etc.
#include <cstdarg>			// for va_start, va_end, etc.
#include <cstring>			// for strlen, strncspn, etc.
#include <filesystem>

// Standard C++ libraries
#include <string>			// for strings processing
#include <vector>			// standard containers
#include <set>				// ''
#include <map>				// ''

// Helper classes
#include <IO.hpp>
#include <ArgvParser.hpp>

#include "parser.cpp"

/* Main function */
int main (int argc, const char ** argv) {

	/* Provide help if called without enough options */
	if (argc<2) {
		printf(
			"CBundle utility version 2.0.1\n"
			"2017-2023, vladikcomper\n"
			"\n"
			"Command line arguments:\n"
			"  cbundle [script_file_path|-] [OPTIONS]\n"
			"\n"
			"NOTICE: Using \"-\" as a script file path redirects input to stdin.\n"
			"\n"
			"OPTIONS:\n"
			"  -out [output_file_path|-]\n"
			"    If set, writes output to the given path, unless overriden by #file directive. Using - will redirect to stdout.\n"
			"\n"
			"  -def [symbol]\n"
			"    Pre-defines a symbol with the given, equivalent to #def [symbol] directive. To specify several symbols, repeat -def [symbol] as many times as needed.\n"
			"\n"
			"  -cwd [dir]\n"
			"    If set, changes current working directory to [dir]. Path can be relative.\n"
			"\n"
			"  -debug\n"
			"    Enable debug output.\n"
			"\n"
			"SUPPORTED DIRECTIVES:\n"
			"\n"
			"  #define <Symbol>\n"
			"    Defines a symbol.\n"
			"\n"
			"  #undef <Symbol>\n"
			"    Removes a symbol from defined symbols list.\n"
			"\n"
			"  #include <FilePath>\n"
			"    Opens the specified file and executes its directives.\n"
			"\n"
			"  #file <FilePath>\n"
			"    Creates or rewrites a file, directs all the output to this file.\n"
			"\n"
			"  #endf\n"
			"    Finishes writing to previously opened file.\n"
			"\n"
			"  #ifdef <Symbol>\n"
			"    Enters IF-block if symbol was defined previously.\n"
			"\n"
			"  #ifndef <Symbol>\n"
			"    Enters IF-block if symbol wasn't defined previously.\n"
			"\n"
			"  #else\n"
			"    Enters ELSE-block if the IF-block's condition wasn't met.\n"
			"\n"
			"  #endif\n"
			"    Ends IF-ELSE-block.\n"
		);
		return 1;
	}

	/* Parse command line arguments */
	const char *inputFileName = argv[1];
	std::string outputFileName = "";
	std::string currentPathOverride = "";
	std::vector<std::string> predefinedSymbols;

	bool optDebug = false;
	{
		const std::map <std::string, ArgvParser::record>
			ParametersList {
				{ "-debug",	{ .type = ArgvParser::record::flag, 		.target = &optDebug 			} },
				{ "-cwd",	{ .type = ArgvParser::record::string,		.target = &currentPathOverride 	} },
				{ "-out",	{ .type = ArgvParser::record::string,		.target = &outputFileName 		} },
				{ "-def",	{ .type = ArgvParser::record::string_list,	.target = &predefinedSymbols 	} },
			};

		/* Decode parameters acording to list defined by "ParametersList" variable */
		try {
			ArgvParser::parse( argv+2, argc-2, ParametersList );
		}
		catch (const char* err) {
			IO::Log( IO::fatal, err );
			return -1;
		}
	}

	IO::LogLevel = optDebug ? IO::debug : IO::warning;

	/* Pre-define symbols of requested */
	if (!predefinedSymbols.empty()) {
		for (auto symbol : predefinedSymbols) {
			Parser::symbols.insert(symbol);
		}
	}

	/* Override current working directory if requested */
	if (!currentPathOverride.empty()) {
		std::filesystem::current_path(std::filesystem::absolute(currentPathOverride));
	}
	
	/* Process input file */
	bool result = false;
	if (!outputFileName.empty()) {
		Parser::parseData out = {
			.file = new IO::FileOutput(outputFileName.c_str()),
			.fileName = outputFileName.c_str(),
			.lineNumber = 0
		};
		result = Parser::parseFile( inputFileName, &out );
	}
	else {
		result = Parser::parseFile( inputFileName );
	}

	if (result == false) {
		IO::Log( IO::fatal, "Bundle generation failed." );
		return -1;
	}

	return 0;

}
