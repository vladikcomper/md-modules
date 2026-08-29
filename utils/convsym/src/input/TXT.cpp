
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for TXT files									*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstdio>
#include <iostream>
#include <string>
#include <string_view>
#include <algorithm>

#include <IO.hpp>
#include <Utils.hpp>
#include <Logger.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__TXT : public InputWrapper {

	Input__TXT(): InputWrapper(std::ios::in) {}
	~Input__TXT() {}

	/** Supported options:
	  *	- `/fmt='format-string'`	- C-style format string (default: '%s %X')
	  *	- `/offsetFirst?`			- specifies whether offset comes first in the input string (default is label followed by offset)
	  */
	struct {
		std::string_view fmt;
		bool offsetFirst;
	} options = { .fmt = "%s %X", .offsetFirst = false };

	void parseOptions(const std::string_view opts) {
		OptsParser::parse(opts, {
			{ "fmt",			OptsParser::Opt::String{ &options.fmt } },
			{ "offsetFirst",	OptsParser::Opt::Bool{ &options.offsetFirst } },
		});
	}

	void parse(SymbolTable& symbolTable, std::istream& input) {
		auto numSpecifiers = std::ranges::count(options.fmt, '%');
		if (numSpecifiers < 2) {
			Logger::warn("Line format string likely has too few arguments (try '%%s %%X')");
		}

		std::string line;
		line.reserve(512);
		std::size_t lineNum = 0;
		const auto sLineFormat = std::string(options.fmt);	/* FIXME: Avoid re-allocation because string_view is not null-terminated */
		while (Utils::getline_safe(input, line)) {
			lineNum++;

			uint32_t offset = 0;
			char sLabel[1024];

			const auto result = options.offsetFirst
				? sscanf(line.c_str(), sLineFormat.c_str(), &offset, sLabel)
				: sscanf(line.c_str(), sLineFormat.c_str(), sLabel, &offset);
			if (result != 2) {
				Logger::debug("Failed to parse line {}, skipping (result={})", lineNum, result);
				continue;
			}

			symbolTable.add(offset, sLabel);
		}
	}

};
