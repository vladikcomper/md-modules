#pragma once

#include <map>
#include <cstdio>
#include <cstdint>
#include <string>
#include <string_view>

#include <OptsParser.hpp>


/* Base class for the output formats handlers */
struct OutputWrapper {
	const enum class PreferredStreamMode { Text, Binary } preferredStreamMode;
	OutputWrapper(PreferredStreamMode mode): preferredStreamMode(mode) { }
	virtual ~OutputWrapper() { }

	virtual void parseOptions(const std::string_view opts) {
		OptsParser::parse(opts, {});
	}

	virtual void parse(std::multimap<uint32_t, std::string>& SymbolMap, std::FILE* output) = 0;
};
