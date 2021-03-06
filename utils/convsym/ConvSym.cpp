
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.7									*
 * Main definitions file										*
 * (c) 2017-2018, 2020-2021, Vladikcomper						*
 * ------------------------------------------------------------	*/

// Standard C-libraries
#include <cstdio>			// for I/O operations and file accesses
#include <cstdint>			// for uint8_t, uint16_t, etc.
#include <cstdarg>			// for va_start, va_end, etc.

// Standard C++ libraries
#include <string>			// for strings processing
#include <vector>			// standard containers
#include <set>				// ''
#include <map>				// ''
#include <functional>		// for generic function template
#include <regex>			// for "regex_match" et al ...

// Helper functions
inline uint16_t swap16( uint16_t x ) { return (x>>8)|(x<<8); };
inline uint32_t swap32( uint32_t x ) { return (x>>24)|((x>>8)&0xFF00)|((x<<8)&0xFF0000)|(x<<24); };

// Helper classes
#include "../core/Huffman.hpp"
#include "../core/BitStream.hpp"
#include "../core/IO.hpp"
#include "../core/ArgvParser.hpp"
#include "../core/OptsParser.hpp"

// I/O wrappers
#include "input/Wrapper.hpp"	// for GetInputWrapper[..]() and their linkage
#include "output/Wrapper.hpp"	// for GetOutputWrapper[..]() and their linkage

/* Main function */
int main (int argc, const char ** argv) {
	
	/* Provide help if no sufficient arguments were passed */
	if (argc<2) {
		printf(
			"ConvSym utility version 2.7\n"
			"2016-2018, 2020-2021, vladikcomper\n"
			"\n"
			"Command line arguments:\n"
			"  convsym [input_file|-] [output_file|-] <options>\n"
			"\n"
			"NOTICE: Using \"-\" as a file name redirects I/O to stdin or stdout respectively.\n"
			"\n"
			"Available options:\n"
			"  -in [format]\n"
			"  -input [format]\n"
			"    Selects input file format. Currently supported format specifiers: asm68k_sym, asm68k_lst, as_lst\n"
			"    Default value is: asm68k_sym\n"
			"\n"
			"  -out [format]\n"
			"  -output [format]\n"
			"    Selects output file format. Currently supported format specifiers: asm, deb1, deb2, log\n"
			"    Default value is: deb2\n"
			"\n"
			"  -base [offset]\n"
			"    Sets the base offset for the input data: it is subtracted from every symbol's offset found in [input_file] to form the final offset. Default value is: 0\n"
			"\n"
			"  -mask [offset]\n"
			"    Sets the mask for the offsets in the input data: it's applied to every offset found in [input_file] after the base offset subtraction (if occurs). Default value is: FFFFFF\n"
			"\n"
			"  -range [bottom] [upper]\n"
			"    Determines the range for offsets allowed in a final symbol file (after subtraction of the base offset), default is: 0 3FFFFF\n"                          
			"\n"
			"  -a\n"
			"    Enables \"Append mode\": symbol data is appended to the end of the [output_file]. Data overwrites file contents by default. This is usually used to append symbols to ROMs.\n"
			"\n"
			"  -org [offset]\n"
			"    If set, symbol data will placed at the specified [offset] in the output file. This option cannot be used in \"append mode\".\n"
			"\n"
			"  -ref [offset]\n"
			"    If set, a 32-bit Big Endian offset pointing to the beginning of symbol data will be written at specified offset. This is can be used, if symbol data pointer must be written somewhere in the ROM header.\n"
			"\n"
			"  -inopt [options]\n"
			"    Additional options for the input parser. There parameters are specific to the selected input format.\n"
			"\n"
			"  -outopt [options]\n"
			"    Additional options for the output parser. There parameters are specific to the selected output format.\n"
			"\n"   
			"  -toupper\n"
			"    Converts all symbol names to uppercase.\n"    
			"\n"   
			"  -tolower\n"
			"    Converts all symbol names to lowercase.\n"
			"\n"
			"  -filter [regex]\n"
			"    Enables filtering of the symbol list fetched from the [input_file] based on a regular expression.\n"
			"\n"
			"  -exclude\n"
			"    If set, filter works in \"exclude mode\": all labels that DO match the -filter regex are removed from the list, everything else stays.\n"
		);
		return -1;
	}

	/* Default configuration */
	bool optAppend = false;								// enable or disable append mode
	bool optDebug = false;								// enable or disable debug output
	bool optFilterExclude = false;						// regex-based filter mode: include or exclude matched symbols
	bool optToUpper = false;
	bool optToLower = false;

	uint32_t baseOffset = 0;
	uint32_t offsetLeftBoundary = 0;
	uint32_t offsetRightBoundary = 0x3FFFFF;
	uint32_t offsetMask = 0xFFFFFF;

	uint32_t appendOffset = 0;
	uint32_t pointerOffset = 0;

	std::string inputWrapperName = "asm68k_sym";		// default input format
	std::string outputWrapperName = "deb2";			// default output format
	std::string inputOpts = "";						// default options for input format
	std::string outputOpts = "";						// default options for output format
	std::string filterRegexStr = "";					// default filter expression

	/* Parse command line arguments */
	const char *inputFileName = argv[1];
	const char *outputFileName = argv[2];
	{
		const std::map <std::string, ArgvParser::record>
			ParametersList {
				{ "-base",		{ type: ArgvParser::record::hexNumber,	target: &baseOffset												} },
				{ "-mask",		{ type: ArgvParser::record::hexNumber,	target: &offsetMask												} },
				{ "-range",		{ type: ArgvParser::record::hexRange,	target: &offsetLeftBoundary,	target2: &offsetRightBoundary	} },
				{ "-a",			{ type: ArgvParser::record::flag,		target: &optAppend												} },
				{ "-debug",		{ type: ArgvParser::record::flag,		target: &optDebug												} },
				{ "-in",		{ type: ArgvParser::record::string,		target: &inputWrapperName										} },
				{ "-input",		{ type: ArgvParser::record::string,		target: &inputWrapperName										} },
				{ "-inopt",		{ type: ArgvParser::record::string,		target: &inputOpts												} },
				{ "-out",		{ type: ArgvParser::record::string,		target: &outputWrapperName										} },
				{ "-output",	{ type: ArgvParser::record::string,		target: &outputWrapperName										} },
				{ "-outopt",	{ type: ArgvParser::record::string,		target: &outputOpts												} },
				{ "-org",		{ type: ArgvParser::record::hexNumber,	target: &appendOffset											} },
				{ "-ref",		{ type: ArgvParser::record::hexNumber,	target: &pointerOffset											} },
				{ "-filter",	{ type: ArgvParser::record::string,		target: &filterRegexStr											} },
				{ "-exclude",	{ type: ArgvParser::record::flag,		target: &optFilterExclude										} },
				{ "-toupper",	{ type: ArgvParser::record::flag,		target: &optToUpper												} },
				{ "-tolower",	{ type: ArgvParser::record::flag,		target: &optToLower												} }
			};

		/* Decode parameters acording to list defined by "ParametersList" variable */
		try {
			ArgvParser::parse( argv+3, argc-3, ParametersList );
		}
		catch (const char* err) {
			IO::Log( IO::fatal, err );
			return -1;
		}

	}

	/* Apply configuration based off the parameters parsed ... */
	IO::LogLevel = optDebug ? IO::debug : IO::warning;
	if ( optAppend == true ) {
		if ( appendOffset != 0 ) {
			IO::Log( IO::warning, "Using conflicting parameters: -a and -org. The -org parameter has no effect" );
		}
		appendOffset = -1;
	}
	if ( optFilterExclude && !filterRegexStr.length() ) {
		IO::Log( IO::warning, "Using -exclude parameter without -filter [regex]. The -exclude parameter has no effect" );
		optFilterExclude = false;
	}
	if ( optToUpper && optToLower ) {
		IO::Log( IO::warning, "Using conflicting parameters: -toupper and -tolower. The -toupper parameter has no effect" );
		optToUpper = false;
	}

	/* Retrieve symbols from the input file */
	std::multimap<uint32_t, std::string> Symbols;
	try {
		InputWrapper * input = getInputWrapper( inputWrapperName );
		Symbols = input->parse( inputFileName, baseOffset, offsetLeftBoundary, offsetRightBoundary, offsetMask, inputOpts.c_str() ); 
		delete input;
	}
	catch (const char* err) {
		IO::Log( IO::fatal, "Input file parsing failed: %s", err ); 
		return -1; 
	}
	
	/* Apply transformation to symbols */
	if ( optToUpper ) {
		for ( auto it = Symbols.begin(); it != Symbols.end(); it++ ) {
			std::transform(it->second.begin(), it->second.end(), it->second.begin(), ::toupper);
		}
		std::transform(filterRegexStr.begin(), filterRegexStr.end(), filterRegexStr.begin(), ::toupper);
	}    
	if ( optToLower ) {
		for ( auto it = Symbols.begin(); it != Symbols.end(); it++ ) {
			std::transform(it->second.begin(), it->second.end(), it->second.begin(), ::tolower);
		}                                                         
		std::transform(filterRegexStr.begin(), filterRegexStr.end(), filterRegexStr.begin(), ::tolower);
	}
	
	/* Pre-filter symbols based on regular expression */
	if ( filterRegexStr.length() > 0 ) {
		const auto regexExpression = std::regex( filterRegexStr );
		for ( auto it = Symbols.cbegin(); it != Symbols.cend(); /*it++*/ ) {	// NOTICE: Do not increment iterator here (but see below)
			bool matched = std::regex_match( it->second, regexExpression );
			if ( matched == optFilterExclude ) {	// will erase element: if mode=exclude and matched, if mode=include and !matched
				it = Symbols.erase( it );
			}
			else {
				it++;
			}
		}
	}

	/* Pass generated symbols list to the output wrapper */
	if ( Symbols.size() > 0 ) {
		try {
			OutputWrapper * output = getOutputWrapper( outputWrapperName );
			output->parse( Symbols, outputFileName, appendOffset, pointerOffset, outputOpts.c_str() );
			delete output;
		}
		catch (const char* err) {
			IO::Log( IO::fatal, "Output generation failed: %s", err );
			return -2;
		}
	}
	else {
		IO::Log( IO::error, "No symbols passed for output, operation aborted" );
	}

	return 0;

}
