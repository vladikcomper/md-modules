
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.11									*
 * Input wrapper for the ASM68K compiler's symbol format		*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <string>
#include <map>

#include <IO.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__ASM68K_Sym : public InputWrapper {

	Input__ASM68K_Sym() : InputWrapper() { }
	~Input__ASM68K_Sym() { }

	/**
	 * Interface for input file parsing
	 *
	 * @param path Input file path
	 * @param baseOffset Base offset for the parsed records (subtracted from the fetched offsets to produce internal offsets)
	 * @param offsetLeftBoundary Left boundary for the calculated offsets
	 * @param offsetRightBoundary Right boundary for the calculated offsets
	 * @param offsetMask Mask applied to offset after base offset subtraction
	 * @param opts Parser options
	 *
	 * @return Sorted associative array (map) of found offsets and their corresponding symbol names
	 */
	std::multimap<uint32_t, std::string> parse(
		const char *fileName,
		uint32_t baseOffset = 0x000000,
		uint32_t offsetLeftBoundary = 0x000000,
		uint32_t offsetRightBoundary = 0x3FFFFF,
		uint32_t offsetMask = 0xFFFFFF,
		const char * opts = ""
	) {
		IO::FileInput input = IO::FileInput( fileName );
		if (!input.good()) { throw "Couldn't open input file"; }

		// Supported options:
		//	/localSign=x			- determines character used to specify local labels
		//	/localJoin=x			- character used to join local label and its global "parent"
		//	/processLocals?			- specify whether local labels will processed

		// Default processing options
		bool optProcessLocalLabels = true;

		// Variables and options
		std::string strLastGlobalLabel("");	// default global label name
		char localLabelSymbol = '@';		// default symbol for local labels
		char localLabelRef = '.';			// default symbol to reference local labels within global ones
		
		const std::map<std::string, OptsParser::record>
			OptsList {
				{ "localSign",			{ .type = OptsParser::record::p_char,	.target = &localLabelSymbol			} },
				{ "localJoin",			{ .type = OptsParser::record::p_char,	.target = &localLabelRef			} },
				{ "processLocals",		{ .type = OptsParser::record::p_bool,	.target = &optProcessLocalLabels	} }
			};
			
		OptsParser::parse( opts, OptsList );	

		// NOTICE: Symbols are usually written OUT OF ORDER in the symbols file,
		//	so we have to map them first before filtering
		std::multimap<uint32_t, std::string> UnfilteredSymbolsMap;
		input.setOffset( 0x0008 );

		for(;;) {

			uint32_t offset;
			try {				// read 32-bit label offset
				offset = input.readLong();
			} catch(...) {		// if reading failed, break
				break;
			}

			input.setOffset( 1, IO::current );					// skip 1 byte

			const size_t labelLength = (size_t)input.readByte();
			char sLabel[255];
			input.readData( (uint8_t*)&sLabel, labelLength );	// read label

			UnfilteredSymbolsMap.insert({ offset, std::string( (const char*)&sLabel, labelLength )});
		}

		// Now we can properly process symbols list IN ORDER
		std::multimap<uint32_t, std::string> SymbolMap;

		for (auto it = UnfilteredSymbolsMap.cbegin(); it != UnfilteredSymbolsMap.cend(); it++) {

			// Construct full label's name as std::string object
			std::string strLabel;

			if (it->second[0] == localLabelSymbol) {
				// Ignore local labels if "processLocals" is disabled
				if ( !optProcessLocalLabels ) {
					IO::Log( IO::debug, "Local symbol ignored: %s", strLabel.c_str() );
					continue;
				}
				strLabel  = strLastGlobalLabel;
				strLabel += localLabelRef;
				strLabel += it->second.substr(1);	// ignore first character of local label
			}
			else {
				strLabel = strLastGlobalLabel = it->second;
			}

			// Finally, add label to the symbols table if it matches the boundaries ...
			uint32_t offset = (it->first - baseOffset) & offsetMask;

			if ( offset >= offsetLeftBoundary && offset <= offsetRightBoundary ) {	// if offset is within range, add it ...
				IO::Log( IO::debug, "Adding symbol: %s", strLabel.c_str() );

				SymbolMap.insert( { offset, strLabel } );
			}
		}

		return SymbolMap;
	}

};

