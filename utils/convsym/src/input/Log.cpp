
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for log files									*
 * ------------------------------------------------------------	*/

#include <cstddef>
#include <cstdint>
#include <fstream>
#include <stdexcept>
#include <string>
#include <map>
#include <iostream>

#include <Logger.hpp>
#include <OptsParser.hpp>
#include <string_view>
#include <utils.hpp>

#include "InputWrapper.hpp"


struct Input__Log : public InputWrapper {

	Input__Log() {}
	~Input__Log() {}

	void parse(SymbolTable& symbolTable, const char *fileName, const char * opts = "") {
		// Supported options:
		//	/separator=x	- determines character that separates labes and offsets, default: ":"
		//	/useDecimal?	- set if offsets should be treat as decimal numbers; default: -

		// Variables and options
		char labelSeparator = ':';
		bool optUseDecimal = false;

		OptsParser::parse(std::string_view(opts), {
			{ "separator",	OptsParser::Opt::Char{ &labelSeparator } },
			{ "useDecimal",	OptsParser::Opt::Bool{ &optUseDecimal } }
		});

		// Define re-usable conditions
		#define IS_HEX_CHAR(X) 			((unsigned)(X-'0')<10||(unsigned)(X-'A')<6||(unsigned)(X-'a')<6)  
		#define IS_NUMERIC(X) 			((unsigned)(X-'0')<10)
		#define SKIP_SPACES(X)			while ( *X==' ' || *X=='\t' ) X++

		std::ifstream fileStream;
		std::istream& input = (std::string_view(fileName) == "-") ? std::cin : (fileStream.open(fileName), fileStream);
		if (input.fail()) {
			throw std::runtime_error("Failed to open input file");
		}

		std::string line;
		line.reserve(512);
		std::size_t lineNum = 0;
		while (getline_safe(input, line)) {
			lineNum++;

			uint8_t* ptr = reinterpret_cast<uint8_t*>(line.data());						// WARNING: Unsigned type is required here for certain range-based optimizations

			SKIP_SPACES(ptr);
			
			// Decode the offset ...
			uint32_t offset = 0;
			if ( optUseDecimal ) {
				while ( IS_NUMERIC(*ptr) ) {
					offset = offset *10 + *ptr-'0';    
					ptr++;
				}
			}
			else {
				while ( IS_HEX_CHAR(*ptr) ) {         
					offset = offset * 0x10 + ( (unsigned)(*ptr-'0')<10 ? (*ptr-'0') : 0xA + ((*ptr-'A'<6) ? (*ptr-'A') : (*ptr-'a') ));
					ptr++;
				}
			}
		
			// If line doesn't include proper separator, skip this line ...
			if ( *ptr++ != labelSeparator ) {
				Logger::debug("Failed to parse line {}, skipping", lineNum);
				continue;
			} 
			SKIP_SPACES(ptr);
			
			// Fetch label ... 
			char* sLabel = (char*)ptr;
			while ( !(*ptr == '\t' || *ptr == ' ') && *ptr ) {
				ptr++;
			}
			*ptr = 0x00;
			
			symbolTable.add(offset, sLabel);
		}
		
		#undef IS_HEX_CHAR
		#undef IS_NUMERIC
		#undef SKIP_SPACES
	}
};
