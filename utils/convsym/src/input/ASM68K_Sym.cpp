
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for the ASM68K compiler's symbol format		*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <ios>
#include <iostream>
#include <fstream>
#include <string>
#include <map>

#include <Logger.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__ASM68K_Sym : public InputWrapper {

	Input__ASM68K_Sym() {}
	~Input__ASM68K_Sym() {}

	void parse(SymbolTable& symbolTable, const char *fileName, const char * opts) {
		std::ifstream fileStream;
		std::istream& input = (std::string_view(fileName) == "-") ? std::cin : (fileStream.open(fileName, std::ios_base::binary), fileStream);
		if (input.fail()) {
			throw std::runtime_error("Failed to open input file");
		}
		input.exceptions(std::ios_base::failbit | std::ios_base::badbit);

		// Supported options:
		//	/localSign=x			- determines character used to specify local labels
		//	/localJoin=x			- character used to join local label and its global "parent"
		//	/processLocals?			- specify whether local labels will processed

		// Default processing options
		bool optProcessLocalLabels = true;

		// Variables and options
		char localLabelSymbol = '@';		// default symbol for local labels
		char localLabelRef = '.';			// default symbol to reference local labels within global ones
		
		const std::map<std::string, OptsParser::record>
			OptsList {
				{ "localSign",			{ .type = OptsParser::record::p_char,	.target = &localLabelSymbol			} },
				{ "localJoin",			{ .type = OptsParser::record::p_char,	.target = &localLabelRef			} },
				{ "processLocals",		{ .type = OptsParser::record::p_bool,	.target = &optProcessLocalLabels	} }
			};
			
		OptsParser::parse(opts, OptsList);

		// NOTICE: Symbols are usually written OUT OF ORDER in the symbols file,
		//	so we have to map them first before filtering
		/* FIXME: Bypass `UnfilteredSymbolsMap` when no local symbols are needed? */
		std::multimap<uint32_t, std::string> UnfilteredSymbolsMap;
		input.seekg(8);

		/* FIXME: Read the entire data to buffer, construct string_view for labels */
		while (input) {
			uint32_t offset;
			try {
				input.read((char*)&offset, 4);	// read 32-bit label offset
			} catch(...) {		// if reading failed, break
				break;
			}

			input.seekg(1, std::ios::cur);					// skip 1 byte

			const size_t labelLength = input.get();
			char sLabel[255];
			input.read(sLabel, labelLength);	// read label

			UnfilteredSymbolsMap.insert({ offset, std::string((const char*)&sLabel, labelLength)});
		}

		/* FIXME: Convert UnfilteredSymbolsMap to array, do std::sort here */

		// Now we can properly process symbols list IN ORDER
		const std::string *lastGlobalLabelRef = &UnfilteredSymbolsMap.cbegin()->second;	// default global label name

		for (const auto & [offset, label]: UnfilteredSymbolsMap) {
			if (label[0] == localLabelSymbol) {
				// Ignore local labels if "processLocals" is disabled
				if ( !optProcessLocalLabels ) {
					Logger::debug("Local symbol ignored: {}", label);
					continue;
				}

				std::string fullLabel = *lastGlobalLabelRef + localLabelRef + label.substr(1);
				symbolTable.add(offset, fullLabel);
			}
			else {
				lastGlobalLabelRef = &label;
				symbolTable.add(offset, label);
			}
		}
	}

};

