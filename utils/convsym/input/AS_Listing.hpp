
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.7.2								*
 * Input wrapper for the AS listing format						*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <map>

#include "../../core/IO.hpp"
#include "../../core/OptsParser.hpp"

#include "InputWrapper.hpp"


struct Input__AS_Listing : public InputWrapper {

	Input__AS_Listing() : InputWrapper() { // Constructor

	}

	~Input__AS_Listing() {	// Destructor

	}

	/**
	 * Interface for input file parsing
	 *
	 * @param path Input file path
	 * @param baseOffset Base offset for the parsed records (subtracted from the fetched offsets to produce internal offsets)
	 * @param offsetLeftBoundary Left boundary for the calculated offsets
	 * @param offsetRightBoundary Right boundary for the calculated offsets
	 * @param offsetMask Mask applied to offset after base offset subtraction
	 *
	 * @return Sorted associative array (map) of found offsets and their corresponding symbol names
	 */
	std::multimap<uint32_t, std::string>
	parse(	const char *fileName,
			uint32_t baseOffset = 0x000000,
			uint32_t offsetLeftBoundary = 0x000000,
			uint32_t offsetRightBoundary = 0x3FFFFF,
			uint32_t offsetMask = 0xFFFFFF,
			const char * opts = "" ) {

		// Default processing options
		bool optProcessLocalLabels = true;
		bool optIgnoreInternalSymbols = true;

		// Variables
		char localLabelSymbol = '.';		// default symbol for local labels
		bool foundSymbolTable = false;

		// Fetch options from "-inopt" argument's value
		const std::map<std::string, OptsParser::record>
			OptsList {
				{ "localJoin",				{ .type = OptsParser::record::p_char,	.target = &localLabelSymbol				} },
				{ "processLocals",			{ .type = OptsParser::record::p_bool,	.target = &optProcessLocalLabels		} },
				{ "ignoreInternalSymbols",	{ .type = OptsParser::record::p_bool,	.target = &optIgnoreInternalSymbols		} }
			};

		// Setup buffer, symbols list and file for input
		const int sBufferSize = 1024;
		uint8_t sBuffer[ sBufferSize ];
		std::multimap<uint32_t, std::string> SymbolMap;
		IO::FileInput input = IO::FileInput( fileName, IO::text );
		if ( !input.good() ) { throw "Couldn't open input file"; }

		// For every string in a listing file ...
		for ( 
				int lineCounter = 0, lineLength; 
				lineLength = input.readLine( sBuffer, sBufferSize ), lineLength >= 0; 
				++lineCounter 
			) {

			// If line is too short, do not proceed
			if (lineLength < 8) {
				continue;
			}

			std::string_view strLine((char*)sBuffer, (size_t)lineLength);

			// Phase 1: Search for symbol table header ...
			if (!foundSymbolTable) {
				// Trim whitespace from the beginning ...
				strLine.remove_prefix(
					std::min(strLine.find_first_not_of(" \t"), strLine.size())
				);
				if (strLine.starts_with("symbol table")) {
					foundSymbolTable = true;

					IO::Log(IO::debug, "Found symbols table header on line %d", lineCounter);
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
					const auto maybeSymbol = this->parseSymbolTableEntry(strLine.substr(left, right-left), optProcessLocalLabels, localLabelSymbol);

					if (maybeSymbol.has_value()) {
						auto symbol = maybeSymbol.value();
						
						if (optIgnoreInternalSymbols && symbol.second.starts_with("__")) continue;

						// Add label to the symbols table
						const auto offset = (symbol.first - baseOffset) & offsetMask;
						if ( offset >= offsetLeftBoundary && offset <= offsetRightBoundary ) {	// if offset is within range, add it ...
							symbol.first = offset;
							IO::Log( IO::debug, "Adding symbol: %s", symbol.second.c_str() );

							SymbolMap.insert(symbol);
						}
					}
				}
			}
		}

		if (!foundSymbolTable) {
			throw "Coudn't find symbols table";
		}

		return SymbolMap;

	}

private:
	std::optional<std::pair<uint32_t, std::string>> parseSymbolTableEntry(const std::string_view &strEntry, bool optProcessLocalLabels, char localLabelSymbol) {
		#define IS_HEX_CHAR(X) 			((unsigned)(X-'0')<10||(unsigned)(X-'A')<6)
		#define IS_START_OF_LABEL(X)	((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||X=='_')
		#define IS_LABEL_CHAR(X)		((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(optProcessLocalLabels&&X==localLabelSymbol)||(unsigned)(X-'0')<10||X=='_')
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
