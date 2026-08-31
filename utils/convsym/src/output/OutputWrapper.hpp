#pragma once

#include <cstdio>
#include <string_view>

#include <OptsParser.hpp>

#include "../util/SymbolTable.hpp"

/* Base class for the output formats handlers */
struct OutputWrapper {
	const enum class PreferredStreamMode { Text, Binary } preferredStreamMode;
	OutputWrapper(PreferredStreamMode mode): preferredStreamMode(mode) { }
	virtual ~OutputWrapper() { }

	virtual void parseOptions(const std::string_view opts) {
		OptsParser::parse(opts, {});
	}

	virtual void parse(std::vector<SymbolTable::Record>& symbols, std::FILE* output) = 0;
};
