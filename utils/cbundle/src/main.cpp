
/* ------------------------------------------------------------ *
 * Bundle Compilation utility v.2.1								*
 *																*
 * Main definitions file										*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

// Standard C-libraries
#include <exception>
#include <filesystem>

// Standard C++ libraries
#include <fstream>
#include <string>			// for strings processing
#include <vector>			// standard containers
#include <iostream>			// for std::cout

// Helper classes
#include <Logger.hpp>
#include <ArgvParser.hpp>

#include "parser.cpp"

/* Main function */
int main (int argc, const char ** argv) {

	/* Provide help if called without enough options */
	if (argc<2) {
		std::cout <<
			"CBundle utility version 2.1\n"
			"2017-2026, vladikcomper\n"
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
		;
		return 1;
	}

	/* Parse command line arguments */
	const char *inputFileName = argv[1];
	std::string outputFileName = "";
	std::string currentPathOverride = "";
	std::vector<std::string> predefinedSymbols;

	bool optDebug = false;
	{
		/* Decode parameters acording to list defined by "ParametersList" variable */
		try {
			ArgvParser::parse(argv+2, argc-2, {
				{ "-debug",	ArgvParser::FlagArg	{ &optDebug }				},
				{ "-cwd",	ArgvParser::Arg		{ &currentPathOverride }	},
				{ "-out",	ArgvParser::Arg		{ &outputFileName }			},
				{ "-def",	ArgvParser::MultiArg{ &predefinedSymbols }		}
			});
		}
		catch (const std::exception& err) {
			Logger::error(err.what());
			return -1;
		}
	}

	Logger::logLevel = optDebug ? Logger::Level::DEBUG : Logger::Level::WARN;

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
		std::ofstream outFile;
		std::ostream& out = (outputFileName == "-") ? std::cout : (outFile.open(outputFileName), outFile);
		if (out.fail()) {
			Logger::error("Failed to open \"{}\" for output.", outputFileName);
			return -2;
		}

		result = Parser::parseFile( inputFileName, &out );
	}
	else {
		result = Parser::parseFile( inputFileName );
	}

	if (result == false) {
		Logger::error("Bundle generation failed.");
		return -1;
	}

	return 0;

}
