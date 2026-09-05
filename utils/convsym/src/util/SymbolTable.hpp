
#pragma once

#include <algorithm>
#include <cstdint>
#include <optional>
#include <variant>
#include <string_view>
#include <vector>

#include "Utils.hpp"
#include "Logger.hpp"

struct OffsetConversionOptions {
	uint32_t baseOffset;
	uint32_t offsetMask;
	uint32_t offsetLowBoundary;
	uint32_t offsetHighBoundary;
};

typedef std::variant<uint32_t, std::string_view> offset_or_symbol;

struct SymbolRef {
	std::string_view label;
	offset_or_symbol* target;
};

/* FIXME: Split Filter? */
struct SymbolTable {
	struct Record {
		uint32_t offset;
		std::string_view label;
	};

	const OffsetConversionOptions& offsetConversionOpts;
	const std::vector<SymbolRef>& symbolRefTable;

	SymbolTable(
		const OffsetConversionOptions& _offsetConversionOpts,
		const std::vector<SymbolRef>& _symbolRefTable
	): offsetConversionOpts(_offsetConversionOpts), symbolRefTable(_symbolRefTable) {
		data.reserve(4096);
	}
	SymbolTable(const SymbolTable&) = delete;
	SymbolTable& operator=(const SymbolTable&) = delete;

	inline bool add(uint32_t offset, std::string_view label) {
		/* FIXME: Move to a dedicated symbol filter pipeline? */
		const uint32_t correctedOffset = (offset - offsetConversionOpts.baseOffset) & offsetConversionOpts.offsetMask;

		/* FIXME: Check if hot path requrires optimization (e.g. manual loop) */
		const auto ref = std::ranges::find(symbolRefTable, label, &SymbolRef::label);
		if (ref != symbolRefTable.end()) {
			*ref->target = correctedOffset;
			Logger::info("Resolved offset for symbol \"{}\": ${:X}", label, correctedOffset);
		}
		if (!(
			correctedOffset >= offsetConversionOpts.offsetLowBoundary && 
			correctedOffset <= offsetConversionOpts.offsetHighBoundary
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
