
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.9.1								*
 * Output wrapper for assembly file with equates				*
 * ------------------------------------------------------------	*/

#include <map>
#include <cstdint>
#include <string>

#include <IO.hpp>

#include "OutputWrapper.hpp"


struct Output__Asm : public OutputWrapper {

	Output__Asm() {};
	~Output__Asm() {};

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
			IO::Log(IO::warning, "Append options aren't supported by the \"asm\" output parser.");
		}

		const char * lineFormat = *opts ? opts : "%s:\tequ\t$%X";
		IO::FileOutput output = IO::FileOutput(fileName, IO::text);
		if (!output.good()) {
			IO::Log(IO::fatal, "Couldn't open file \"%s\"", fileName);
			throw "IO error";
		}

		for (auto& symbol : SymbolList) {
			output.writeLine(lineFormat, symbol.second.c_str(), symbol.first);
		}
	}

};
