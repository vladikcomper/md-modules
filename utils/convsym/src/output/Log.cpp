
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Output wrapper for simple symbol logging						*
 * ------------------------------------------------------------	*/

#include <map>
#include <cstdint>
#include <string>
#include <algorithm>

#include <IO.hpp>
#include <Logger.hpp>

#include "OptsParser.hpp"
#include "OutputWrapper.hpp"


struct Output__Log : public OutputWrapper {

	Output__Log() {};
	~Output__Log() {};

	/**
	 * Main function that generates the output
	 */
	void parse(
		std::multimap<uint32_t, std::string>& SymbolList,
		const char * fileName,
		uint32_t appendOffset = 0,
		uint32_t pointerOffset = 0,
		const char * opts = "",
		bool alignOnAppend = true
	) {
		if (appendOffset || pointerOffset || !alignOnAppend) {
			Logger::warn("Append options aren't supported by the \"log\" output parser.");
		}

		// Supported options:
		//	/fmt='format-string' 	- overrides C-style format string (default: '%X: %s')

		// Default options
		std::string lineFormat = "%X: %s";

		if (*opts && opts[0] == '/') {
			const std::map<std::string, OptsParser::record>
			OptsList {
				{ "fmt", { .type = OptsParser::record::p_string, .target = &lineFormat	} }
			};
			OptsParser::parse(opts, OptsList);
		}
		else if (*opts) {
			lineFormat = opts;
		}
		auto numSpecifiers = std::ranges::count(lineFormat, '%');
		if (numSpecifiers < 2) {
			Logger::warn("Line format string likely has too few arguments (try '%%X: %%s')");
		}

		IO::FileOutput output = IO::FileOutput(fileName, IO::text);
		if (!output.good()) {
			Logger::error("Couldn't open file \"{}\"", fileName);
			throw "IO error";
		}

		for (auto & symbol : SymbolList ) {
			output.writeLine(lineFormat.c_str(), symbol.first, symbol.second.c_str());
		}
	}
};
