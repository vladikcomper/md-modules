
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.13									*
 * Input wrapper for the ASM68K compiler's symbol format		*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstring>
#include <ios>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>

#include <Logger.hpp>
#include <OptsParser.hpp>
#include <vector>

#include "InputWrapper.hpp"


struct Input__ASM68K_Sym : public InputWrapper {

	Input__ASM68K_Sym(): InputWrapper(std::ios::in) {}
	~Input__ASM68K_Sym() {}

	/** Supported options:
	  *	- `/localSign=x` 		- determines character used to specify local labels
	  *	- `/localJoin=x` 		- character used to join local label and its global "parent"
	  *	- `/processLocals?`		- specify whether local labels will processed
	  * - `/ignoreConstants?`	- whether linker constants (e.g. `_ROM_OBJ`) should be ignored
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
					if (!options.processLocals && label[0] == options.localSign) break;
					symbolTable.add(offset, label);
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
					input.seekg(2, std::ios::cur);	// skip 2 bytes
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

		if (options.processLocals) {
			symbolTable.sortByOffset();

			/* FIXME: What if this label is local? */
			std::string_view lastGlobalLabel = symbolTable.data.at(0).label;	// default global label name
			for (auto & [offset, label]: symbolTable.data) {
				if (label[0] == options.localSign) {
					label = symbolTable.arena.push_concat(lastGlobalLabel, options.localJoin, label.substr(1));
				}
				else {
					lastGlobalLabel = label;
				}
			}
		}
	}

};

