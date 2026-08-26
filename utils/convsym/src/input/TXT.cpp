
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for TXT files									*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <algorithm>

#include <IO.hpp>
#include <utils.hpp>
#include <Logger.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__TXT : public InputWrapper {

	Input__TXT() {}
	~Input__TXT() {}

	void parse(SymbolTable& symbolTable, const char *fileName, const char * opts) {

		// Supported options:
		//	/fmt='format-string'	- C-style format string (default: '%s %X')
		//	/offsetFirst?			- specifies whether offset comes first in the input string (default is label followed by offset)

		// Default options
		std::string lineFormat = "%s %X";
		bool offsetFirst = false;

		const std::map<std::string, OptsParser::record>
			OptsList {
				{ "fmt",			{ .type = OptsParser::record::p_string,	.target = &lineFormat } },
				{ "offsetFirst",	{ .type = OptsParser::record::p_bool,	.target = &offsetFirst } },
			};
		OptsParser::parse(opts, OptsList);

		std::string line;
		std::ifstream fileStream;
		std::istream& input = (std::string_view(fileName) == "-") ? std::cin : (fileStream.open(fileName), fileStream);
		if (input.fail()) {
			throw std::runtime_error("Failed to open input file");
		}

		auto numSpecifiers = std::ranges::count(lineFormat, '%');
		if (numSpecifiers < 2) {
			Logger::warn("Line format string likely has too few arguments (try '%%s %%X')");
		}

		std::size_t lineNum = 0;
		const auto lineFormat_cstr = lineFormat.c_str();
		while (getline_safe(input, line)) {
			lineNum++;

			uint32_t offset = 0;
			char sLabel[512];

			const auto result = offsetFirst
				? sscanf(line.c_str(), lineFormat_cstr, &offset, sLabel)
				: sscanf(line.c_str(), lineFormat_cstr, sLabel, &offset);
			if (result != 2) {
				Logger::debug("Failed to parse line {}, skipping (result={})", lineNum, result);
				continue;
			}

			symbolTable.add(offset, sLabel);
		}
	}

};
