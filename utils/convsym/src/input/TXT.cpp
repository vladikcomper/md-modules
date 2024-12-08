
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.10									*
 * Input wrapper for TXT files									*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <map>
#include <set>
#include <algorithm>

#include <IO.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__TXT : public InputWrapper {

	Input__TXT() : InputWrapper() {}
	~Input__TXT() {}

	/**
	 * Interface for input file parsing
	 *
	 * @param path Input file path
	 * @param baseOffset Base offset for the parsed records (subtracted from the fetched offsets to produce internal offsets)
	 * @param offsetLeftBoundary Left boundary for the calculated offsets
	 * @param offsetRightBoundary Right boundary for the calculated offsets
	 * @param offsetMask Mask applied to offset after base offset subtraction
	 *
	 * @return Sorted associative array (map) of found offsets and their corresponding symbol names
	 */
	std::multimap<uint32_t, std::string> parse(
		const char *fileName,
		uint32_t baseOffset = 0x000000,
		uint32_t offsetLeftBoundary = 0x000000,
		uint32_t offsetRightBoundary = 0x3FFFFF,
		uint32_t offsetMask = 0xFFFFFF,
		const char * opts = ""
	) {

		// Supported options:
		//	/fmt='format-string'	- C-style format string (default: '%s %X')
		//	/offsetFirst?			- specifies whether offset comes first in the input string (default is label followed by offset)

		// Default options
		std::string lineFormat = "%s %X";
		bool offsetFirst = false;

		static const std::map<std::string, OptsParser::record>
			OptsList {
				{ "fmt",			{ .type = OptsParser::record::p_string,	.target = &lineFormat } },
				{ "offsetFirst",	{ .type = OptsParser::record::p_bool,	.target = &offsetFirst } },
			};
		OptsParser::parse(opts, OptsList);
		
		// Setup buffer, symbols list and file for input
		const int sBufferSize = 1024;
		uint8_t sBuffer[sBufferSize];
		std::multimap<uint32_t, std::string> SymbolMap;
		IO::FileInput input = IO::FileInput(fileName, IO::text);
		if (!input.good()) { 
			throw "Couldn't open input file"; 
		}

		auto numSpecifiers = std::ranges::count(lineFormat, '%');
		if (numSpecifiers < 2) {
			IO::Log(IO::warning, "Line format string likely has too few arguments (try '%%s %%X')");
		}

		int lineNum = 0;
		const auto lineFormat_cstr = lineFormat.c_str();
		while (input.readLine(sBuffer, sBufferSize) >= 0) {
			lineNum++;

			uint32_t offset = 0;
			char sLabel[512];

			const auto result = offsetFirst
				? sscanf((const char*)sBuffer, lineFormat_cstr, &offset, sLabel)
				: sscanf((const char*)sBuffer, lineFormat_cstr, sLabel, &offset);
			if (result != 2) {
				IO::Log(IO::debug, "Failed to parse line %d, skipping (result=%d)", lineNum, result);
				continue;
			}

			// Add label to the symbols table
			offset = (offset - baseOffset) & offsetMask;
			if ( offset >= offsetLeftBoundary && offset <= offsetRightBoundary ) {	// if offset is within range, add it ...
				IO::Log(IO::debug, "Adding symbol: %s", sLabel);
				SymbolMap.insert({ offset, std::string(sLabel) });
			}
		}

		return SymbolMap;
	}

};
