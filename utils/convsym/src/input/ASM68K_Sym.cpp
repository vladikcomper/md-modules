
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for the ASM68K compiler's symbol format		*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstring>
#include <ios>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <map>

#include <Logger.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__ASM68K_Sym : public InputWrapper {

	Input__ASM68K_Sym(): InputWrapper(std::ios::in) {}
	~Input__ASM68K_Sym() {}

	/** Supported options:
	  *	- `/localSign=x` 		- determines character used to specify local labels
	  *	- `/localJoin=x` 		- character used to join local label and its global "parent"
	  *	- `/processLocals?`		- specify whether local labels will processed
	  * - `/ignoreConstants?`	- whether linker constants (e.g. `_ROM_OBJ` will be ignored)
	  */
	struct {
		char localSign;
		char localJoin;
		bool processLocals;
		bool ignoreConstants;
	} options = { .localSign = '@', .localJoin = '.', .processLocals = true, .ignoreConstants = true };

	void parseOptions(const std::string_view opts) {
		OptsParser::parse(opts, {
			{ "localSign",		OptsParser::Opt::Char{ &options.localSign } },
			{ "localJoin",		OptsParser::Opt::Char{ &options.localJoin } },
			{ "processLocals",	OptsParser::Opt::Bool{ &options.processLocals } },
			{ "ignoreConstants", OptsParser::Opt::Bool{ &options.ignoreConstants } }
		});
	}

	void parse(SymbolTable& symbolTable, std::istream& input) {
		input.exceptions(std::ios_base::failbit | std::ios_base::badbit);

		// NOTICE: Symbols are usually written OUT OF ORDER in the symbols file,
		//	so we have to map them first before filtering
		/* FIXME: Bypass `UnfilteredSymbolsMap` when no local symbols are needed? */
		std::multimap<uint32_t, std::string> UnfilteredSymbolsMap;
		
		/* Validate header */
		struct SymHeader {
			char magic[3];		// "MND"
			uint8_t version;
			uint32_t targetUnit;
		} header;
		static_assert(sizeof(header) == 8);

		input.read(reinterpret_cast<char*>(&header), sizeof(header));
		if ((std::strncmp(header.magic, "MND", 3) != 0) || (header.version != 0x01)) {
			throw std::runtime_error("Not a valid .sym file: Incorrect header or version");
		}

		/* FIXME: Read the entire data to buffer, construct string_view for labels */
		while (input) {
			/* Read symbol offset and type */
			uint32_t offset;
			try {
				input.read(reinterpret_cast<char*>(&offset), 4);
			}
			catch (...) {
				break;
			}
			uint8_t type = input.get();

			Logger::debug("Got offset {}, type {:X}", offset, type);

			/* Parse symbol payload, depending on type */
			switch (type) {
				/* Normal symbols */
				case 0x01:		// `equ` symbol
				case 0x02:		// global symbol
				case 0x05:
				case 0x06: {	// local symbol
					std::size_t labelLen = input.get();
					std::string label;
					label.resize_and_overwrite(labelLen, [&](char* buff, std::size_t buff_size) {
						input.read(buff, labelLen);
						return labelLen;
					});
					Logger::debug("Insert symbol: {}", label);
					if (options.ignoreConstants && type == 0x01) break;
					UnfilteredSymbolsMap.emplace(offset, label);
					break;
				}

				/* Source Line Data (SLD) blocks (ignored) */
				case 0x80:		// Inc SLD
				case 0x8A:		// End SLD
					break;
				case 0x82:		// Inc SLD by byte
					input.get();					// skip 1 byte
					break;
				case 0x84:		// Inc SLD by word
					input.seekg(4, std::ios::cur);	// skip 2 bytes
					break;
				case 0x86:		// Set SLD (longword)
					input.seekg(4, std::ios::cur);	// skip 4 bytes
					break;
				case 0x88: {	// Set SLD to line and file
					input.seekg(4, std::ios::cur);	// skip 4 bytes
					input.seekg(input.get(), std::ios::cur); // skip path payload
					break;
				}
				default:
					throw std::runtime_error(std::format("Unknown symbol type: {:2X}", type));
			}
		}

		/* FIXME: Convert UnfilteredSymbolsMap to array, do std::sort here */

		// Now we can properly process symbols list IN ORDER
		const std::string *lastGlobalLabelRef = &UnfilteredSymbolsMap.cbegin()->second;	// default global label name

		for (const auto & [offset, label]: UnfilteredSymbolsMap) {
			if (label[0] == options.localSign) {
				// Ignore local labels if "processLocals" is disabled
				if ( !options.processLocals ) {
					Logger::debug("Local symbol ignored: {}", label);
					continue;
				}

				std::string fullLabel = *lastGlobalLabelRef + options.localJoin + label.substr(1);
				symbolTable.add(offset, fullLabel);
			}
			else {
				lastGlobalLabelRef = &label;
				symbolTable.add(offset, label);
			}
		}
	}

};

