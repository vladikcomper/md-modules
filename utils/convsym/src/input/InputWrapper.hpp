
#pragma once

#include <istream>
#include <string_view>

#include <OptsParser.hpp>

#include "../util/SymbolTable.hpp"

/* Base class for the input formats handlers */
struct InputWrapper {
	const std::ios::openmode preferredStreamMode;
	InputWrapper(std::ios::openmode mode): preferredStreamMode(mode) {}
	virtual ~InputWrapper() {}

	/* FIXME: Rename to `setOptions`? */
	virtual void parseOptions(const std::string_view opts)  {
		OptsParser::parse(opts, {});
	}

	virtual void parse(SymbolTable& symbolTable, std::istream& input) = 0;
};
