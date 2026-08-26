
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <map>
#include <unordered_map>

#include "Logger.hpp"

struct OffsetConversionOptions {
	uint32_t baseOffset;
	uint32_t offsetLeftBoundary;
	uint32_t offsetRightBoundary;
	uint32_t offsetMask;
};

typedef std::unordered_map<std::string_view, std::reference_wrapper<uint32_t>> SymbolToOffsetResolveTable;

struct SymbolTable {
	const OffsetConversionOptions& offsetConversionOpts;
	const SymbolToOffsetResolveTable& symbolToOffsetResolveTable;

	std::multimap<uint32_t,std::string> symbols;

	SymbolTable(
		const OffsetConversionOptions& _offsetConversionOpts,
		const SymbolToOffsetResolveTable& _symbolToOffsetResolveTable
	): offsetConversionOpts(_offsetConversionOpts), symbolToOffsetResolveTable(_symbolToOffsetResolveTable), symbols({}) {}

	SymbolTable(const SymbolTable& symbolTable) = delete;
	SymbolTable& operator=(const SymbolTable& symbolTable) = delete;

	/* FIXME: Move this complexity outside of .add calls */
	/* FIXME: If symbols are sorted, we can cut off unwanted offsets early */
	template<typename LabelType>
	inline bool add(uint32_t offset, LabelType label) {
		const uint32_t correctedOffset = (offset - offsetConversionOpts.baseOffset) & offsetConversionOpts.offsetMask;

		/* If we have symbols to resolve for some options (e.g. `-ref sym:MySymbolName`), resolve to offset if name matches */
		if (!symbolToOffsetResolveTable.empty()) {
			/* FIXME: Do this resolution AFTER processing the entire input, use hash table */
			const auto symbolToOffsetEntry = symbolToOffsetResolveTable.find(label);
			if (symbolToOffsetEntry != symbolToOffsetResolveTable.end()) {
				symbolToOffsetEntry->second.get() = correctedOffset;
				Logger::debug("Resolved requested symbol offset: {:X}", correctedOffset);
			}
		}
		/* FIXME: Do this resolution AFTER processing the entire input, allows to specify left/right boundary as symbols! */
		if (!(
			correctedOffset >= offsetConversionOpts.offsetLeftBoundary && 
			correctedOffset <= offsetConversionOpts.offsetRightBoundary
		)) {
			return false;	// symbol is not inserted when offset is out of range
		}

		Logger::debug("Adding symbol: {}", label);
		symbols.emplace(correctedOffset, std::string(label));

		return true;
	}

};
