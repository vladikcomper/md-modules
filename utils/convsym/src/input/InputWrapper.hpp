
#pragma once

#include <string_view>

#include <OptsParser.hpp>

#include "../util/SymbolTable.hpp"

/* Base class for the input formats handlers */
struct InputWrapper {
	InputWrapper() {}
	virtual ~InputWrapper() {}

	virtual void parseOptions(const std::string_view opts)  {
		OptsParser::parse(opts, {});
	}

	virtual void parse(SymbolTable& symbolTable, const char *fileName) = 0;
};
