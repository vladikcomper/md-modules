
#pragma once

#include <algorithm>
#include <cstdint>
#include <unordered_map>
#include <string_view>
#include <vector>

#include "Utils.hpp"
#include "Logger.hpp"

struct OffsetConversionOptions {
	uint32_t baseOffset;
	uint32_t offsetLeftBoundary;
	uint32_t offsetRightBoundary;
	uint32_t offsetMask;
};

typedef std::unordered_map<std::string_view, std::reference_wrapper<uint32_t>> SymbolToOffsetResolveTable;

/* FIXME: Split Filter? */
struct SymbolTable {
	struct Record {
		uint32_t offset;
		std::string_view label;
	};

	const OffsetConversionOptions& offsetConversionOpts;
	const SymbolToOffsetResolveTable& symbolToOffsetResolveTable;

	SymbolTable(
		const OffsetConversionOptions& _offsetConversionOpts,
		const SymbolToOffsetResolveTable& _symbolToOffsetResolveTable
	): offsetConversionOpts(_offsetConversionOpts), symbolToOffsetResolveTable(_symbolToOffsetResolveTable) {
		data.reserve(4096);
	}
	SymbolTable(const SymbolTable&) = delete;
	SymbolTable& operator=(const SymbolTable&) = delete;

	inline bool add(uint32_t offset, std::string_view label) {
		/* FIXME: Move to a dedicated symbol filter pipeline? */
		/* Verify if symbol should be inserted */
		const uint32_t correctedOffset = (offset - offsetConversionOpts.baseOffset) & offsetConversionOpts.offsetMask;
		if (!symbolToOffsetResolveTable.empty()) {
			const auto symbolToOffsetEntry = symbolToOffsetResolveTable.find(label);
			if (symbolToOffsetEntry != symbolToOffsetResolveTable.end()) {
				symbolToOffsetEntry->second.get() = correctedOffset;
				Logger::debug("Resolved requested symbol offset: {:X}", correctedOffset);
			}
		}
		if (!(
			correctedOffset >= offsetConversionOpts.offsetLeftBoundary && 
			correctedOffset <= offsetConversionOpts.offsetRightBoundary
		)) {
			return false;	// symbol is not inserted when offset is out of range
		}

		data.emplace_back(correctedOffset, arena.push(label));
		return true;
	}

	inline void sortByOffset() {
		std::ranges::stable_sort(data, {}, &Record::offset);
	}

	std::vector<Record> data;
	Utils::StringArena arena;
};
