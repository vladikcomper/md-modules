
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for the AS listing format						*
 * ------------------------------------------------------------	*/

#include <cstddef>
#include <cstdint>
#include <optional>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>

#include <IO.hpp>
#include <Logger.hpp>
#include <OptsParser.hpp>
#include <Utils.hpp>

#include "InputWrapper.hpp"


struct Input__AS_Listing : public InputWrapper {

	explicit Input__AS_Listing(): InputWrapper(std::ios::in) {}
	~Input__AS_Listing() {}

	/** Supported options:
	  *	- `/localJoin=x` - character used to join local label and its global "parent"
	  *	- `/processLocals?` - specify whether local labels will processed
	  * - `/ignoreInternalSymbols? - whether to ignore AS internal symbols (start with `__`)
	  */
	struct { 
		char localJoin;
		bool processLocals;
		bool ignoreInternalSymbols;
	} options = { .localJoin = '.', .processLocals = true, .ignoreInternalSymbols = true };

	void parseOptions(const std::string_view opts) {
		OptsParser::parse(std::string_view(opts), {
			{ "localJoin", 				OptsParser::Opt::Char{ &options.localJoin } },
			{ "processLocals",			OptsParser::Opt::Bool{ &options.processLocals } },
			{ "ignoreInternalSymbols",	OptsParser::Opt::Bool{ &options.ignoreInternalSymbols } },
		});
	}

	void parse(SymbolTable& symbolTable, std::istream& input) {
		bool foundSymbolTable = false;

		// For every string in a listing file ...
		std::string line;
		line.reserve(1024);
		std::size_t lineCounter = 0;
		while (Utils::getline_safe(input, line)) {
			lineCounter++;
			if (line.size() < 8) continue;	// if line is too short, ignore it

			std::string_view strLine(line);

			// Phase 1: Search for symbol table header ...
			if (!foundSymbolTable) {
				// Trim whitespace from the beginning ...
				strLine.remove_prefix(
					std::min(strLine.find_first_not_of(" \t"), strLine.size())
				);
				// Newer versions of AS seem to output "Symbol Table" string instead of "symbol table"
				if (strLine.starts_with("symbol table") || strLine.starts_with("Symbol Table")) {
					foundSymbolTable = true;

					Logger::debug("Found symbols table header on line {}", lineCounter);
				}
			}

			// Phase 2: Parse the symbol table
			else {
				// If line include table separator '|', process cells and extract labels and offsets from them ...
				// NOTICE: This loop won't yield any results if '|' is absent completely.
				for (
					size_t left = 0, right = strLine.find_first_of('|');
					right != std::string_view::npos;
					left = right + 1, right = strLine.find_first_of('|', left)
				) {
					const auto maybeSymbol = this->parseSymbolTableEntry(strLine.substr(left, right-left));

					if (maybeSymbol.has_value()) {
						auto symbol = maybeSymbol.value();

						if (options.ignoreInternalSymbols && symbol.second.starts_with("__")) continue;

						symbolTable.add(symbol.first, symbol.second);
					}
				}
			}
		}

		if (!foundSymbolTable) {
			throw std::runtime_error("Coudn't find symbols table");
		}
	}

private:
	inline std::optional<std::pair<uint32_t, std::string>> parseSymbolTableEntry(const std::string_view &strEntry) {
		#define IS_HEX_CHAR(X) 			((unsigned)(X-'0')<10||(unsigned)(X-'A')<6)
		#define IS_START_OF_LABEL(X)	((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||X=='_')
		#define IS_LABEL_CHAR(X)		((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(options.processLocals&&X==options.localJoin)||(unsigned)(X-'0')<10||X=='_')
		#define IS_WHITESPACE(X)		(X==' '||X=='\t')

		const auto end = strEntry.cend();
		auto it = strEntry.cbegin();

		// Skip whitespace at the beginning ...
		while ( it != end && (IS_WHITESPACE(*it) || *it == '*') ) ++it;

		// Capture label ...
		if ( it == end || !(IS_START_OF_LABEL(*it)) ) return std::nullopt;
		const auto labelBegin = it++;
		while ( it != end && IS_LABEL_CHAR(*it) ) ++it;
		const auto labelEnd = it;

		// Skip " : " and following whitespace
		if ( it == end || *it++ != ' ' ) return std::nullopt;
		if ( it == end || *it++ != ':' ) return std::nullopt;
		while ( it != end && IS_WHITESPACE(*it) ) ++it;

		// Capture offset ...
		if ( it == end || !(IS_HEX_CHAR(*it)) ) return std::nullopt;
		uint32_t offset = 0;
		while ( it != end && IS_HEX_CHAR(*it) ) {
			offset = offset * 0x10 + (((unsigned)(*it-'0')<10) ? (*it-'0') : (*it-('A'-10)));
			++it;
		}

		// Capture label type ...
		if ( it == end || *it++ != ' ' ) return std::nullopt;
		if ( it == end || *it++ != 'C' ) return std::nullopt;

		// Return results
		return std::optional<std::pair<uint32_t, std::string>>{ { offset, std::string(labelBegin, labelEnd) } };

		#undef IS_HEX_CHAR
		#undef IS_START_OF_LABEL
		#undef IS_LABEL_CHAR
		#undef IS_WHITESPACE
	}
};
