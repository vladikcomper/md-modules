
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Output wrapper for assembly file with equates				*
 * ------------------------------------------------------------	*/

#include <map>
#include <cstdio>
#include <cstdint>
#include <string>
#include <algorithm>
#include <string_view>

#include <Logger.hpp>

#include "OptsParser.hpp"
#include "OutputWrapper.hpp"


struct Output__Asm : public OutputWrapper {

	Output__Asm() {};
	~Output__Asm() {};

	/** Supported options:
	  *	- `/fmt='format-string'`	- overrides C-style format string (default: '%s:\tequ\t$%X')
	  */
	struct {
		std::string_view fmt;
	} options = { .fmt = "%s:\tequ\t$%X" };

	void parseOptions(const std::string_view opts) {
		if (opts.empty()) return;
		if (opts[0] == '/') {
			OptsParser::parse(opts, {
				{ "fmt", OptsParser::Opt::String{ &options.fmt } }
			});
		}
		else {
			options.fmt = opts;
		}
	}

	/**
	 * Main function that generates the output
	 */
	void parse(
		std::multimap<uint32_t, std::string>& SymbolList,
		const char * fileName,
		uint32_t appendOffset = 0,
		uint32_t pointerOffset = 0,
		bool alignOnAppend = true
	) {
		if (appendOffset || pointerOffset || !alignOnAppend) {
			Logger::warn("Append options aren't supported by the \"asm\" output parser.");
		}

		auto numSpecifiers = std::ranges::count(options.fmt, '%');
		if (numSpecifiers < 2) {
			Logger::warn("Line format string likely has too few arguments (try '%%s:\tequ\t$%%X')");
		}

		std::FILE * output = std::string_view(fileName) == "-" ? stdout : std::fopen(fileName, "w");
		if (!output) {
			throw std::runtime_error("Failed to open output file");
		}

		const auto sLineFormat = std::string(options.fmt);	/* FIXME: Avoid re-allocation because string_view is not null-terminated */

		for (const auto & symbol : SymbolList) {
			std::fprintf(output, sLineFormat.c_str(), symbol.second.c_str(), symbol.first);
			std::fputc('\n', output);
		}

		if (output != stdout) std::fclose(output);
	}
};
