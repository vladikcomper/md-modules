
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.13									*
 * Output wrapper for the Debug Information format version 1.0	*
 * ------------------------------------------------------------	*/

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <stdexcept>

#include <OptsParser.hpp>
#include <Huffman.hpp>
#include <BitStream.hpp>
#include <Logger.hpp>
#include <Utils.hpp>

#include "OutputWrapper.hpp"


struct Output__Deb1 : public OutputWrapper {

	Output__Deb1(): OutputWrapper(OutputWrapper::PreferredStreamMode::Binary) {};
	~Output__Deb1() {};

	/** Supported options:
	  *	- `/favorLastLabels?`	- load only the last label for duplicated offsets (default: first)
	  */
	struct {
		bool favorLastLabels;
	} options = { .favorLastLabels = false };

	void parseOptions(const std::string_view opts) {
		OptsParser::parse(opts, {
			{ "favorLastLabels", OptsParser::Opt::Bool{ &options.favorLastLabels } }
		});
	}

	/**
	 * Main function that generates the output
	 */
	void parse(std::vector<SymbolTable::Record>& symbols, FILE* output) {
		assert(!symbols.empty());

		/* Write format version token */
		constexpr uint16_t magic = Utils::asBigEndian<uint16_t>(0xDEB1);
		std::fwrite(&magic, 2, 1, output);

		/* Allocate space for blocks offsets table */
		auto lastSymbolPtr = symbols.rbegin();
		uint16_t lastBlock = (lastSymbolPtr->offset) >> 16;

		if (lastBlock > 63) {		// blocks index table is limited to $40 entries (which is only enough to ROM section)
			Logger::warn("Too many memory blocks to allocate (${:X}), truncating to $40 blocks. Some symbols will be lost.", lastBlock+1);
			lastBlock = 0x3F;
		}

		uint16_t blockOffsets[0x40] = { 0 };
		uint16_t dataOffsets[0x40] = { 0 };

		const uint32_t loc_BlockOffsets = std::ftell(output);	// remember the offset where blocks offset table should start
		std::fwrite(blockOffsets, 0x40, 2, output);				// dummy writes to reserve space (will be overwritten later)
		std::fwrite(dataOffsets, 0x40, 2, output);				// ''

		/* ------------------------------------------------ */
		/* Generate Huffman-codes and create decoding table */
		/* ------------------------------------------------ */

		Logger::debug("Building an encoding table...");

		/* Generate table of character frequencies based on symbol names */
		uint32_t freqTable[0x100] = { 0 };
		for (const auto& [_, label] : symbols) {
			for (auto& character : label) {
				freqTable[(int)character]++;
			}
			freqTable[0x00]++;
		}

		/* Generate table of Huffman codes (sorted by code) */
		Huffman::RecordSet codesTable = Huffman::encode(freqTable);

		/* Write down the decoding table */
		const Huffman::Record* characterToRecord[0x100] = { nullptr };	// LUT that links each character to its Huffman-coding record
		{
			std::vector<uint16_t> huffmanTableBuff(codesTable.size() * 2 + 1);
			std::size_t tablePos = 0;
			for (auto& entry : codesTable) {
				/* FIXME: This shouldn't happen as Huffman encoder auto-flattens tree */
				if (entry.codeLength > 16) {
					throw std::runtime_error("Some encoding table code lengths exceed 16 bits, try -tolower or -toupper option to reduce entropy");
				}

				characterToRecord[entry.data] = &entry;		// assign character this Huffman::Record entity

				huffmanTableBuff[tablePos++] = Utils::asBigEndian<uint16_t>(entry.code);
				huffmanTableBuff[tablePos++] = Utils::asBigEndian<uint16_t>((entry.codeLength << 8) | (entry.data));
			}
			huffmanTableBuff[tablePos] = -1;		// write 0xFFFF at the end of Huffman-table to stop searching and cause error
			std::fwrite(huffmanTableBuff.data(), huffmanTableBuff.size(), 2, output);
		}

		/* ------------------------------------- */
		/* Generate per block symbol information */
		/* ------------------------------------- */

		{
			Logger::debug("Generating symbol data blocks...");

			auto symbolPtr = symbols.begin();

			/* For 64kb block within symbols range */
			for (uint16_t block = 0x00; block <= lastBlock; block++) {
				uint32_t loc_Block = std::ftell(output);
				if (loc_Block & 1) {
					std::fputc(0x00, output);
					loc_Block++;
				}

				std::vector<uint16_t> offsetsData;
				std::vector<uint8_t> symbolsData;

				/* For every symbol within the block ... */
				for (; (symbolPtr->offset>>16) <= block && (symbolPtr != symbols.cend()); ++symbolPtr) {
					if ((symbolPtr->offset>>16) < block) {
						continue;
					}

					Logger::debug("\t{:08X}\t{}", symbolPtr->offset, symbolPtr->label);

					/* 
					 * For records with the same offsets, fetch only the last or the first processed symbol,
					 * depending "favor last labels" option ...
					 */
					if ( (options.favorLastLabels && std::next(symbolPtr) != symbols.end()
								&& std::next(symbolPtr)->offset == symbolPtr->offset) ||
						 (!options.favorLastLabels && symbolPtr != symbols.begin()
								&& std::prev(symbolPtr)->offset == symbolPtr->offset) ) {
						continue;
					}

					BitStream symbolHeap;

					/* Add offset to the offsets block */
					offsetsData.push_back(Utils::asBigEndian<uint16_t>(symbolPtr->offset & 0xFFFF));

					/* Encode each symbol character with the generated Huffman-codes and store it in the bitsteam */
					for (auto& Character : symbolPtr->label) {
						auto *record = characterToRecord[(int)Character];
						symbolHeap.pushCode(record->code, record->codeLength);
					}

					/* Finally, add null-terminator */
					{
						auto *record = characterToRecord[0x00];
						symbolHeap.pushCode(record->code, record->codeLength);
					}

					/* Push this symbol to the data buffer */
					/* FIXME: Avoid data transfer back and forth, push data to bitstream directly */
					symbolsData.push_back(symbolHeap.size() + 1);	// write down symbols size
					for (auto t = symbolHeap.begin(); t != symbolHeap.end(); t++) {
						symbolsData.push_back(*t);
					}
				}

				/* Write offsets block and their corresponding encoded symbols heap */
				if (offsetsData.size() > 0) {
					/* Add zero offset to finalize the block */
					offsetsData.push_back(0x0000);
					
					/* Check for pointer capacity limits */
					if ( (loc_Block - loc_BlockOffsets)>>1 > 0xFFFF
						|| (loc_Block+offsetsData.size()*2 - loc_BlockOffsets)>>1 > 0xFFFF ) {
						Logger::warn("Block {:02X} is either too large, or symbol file has exceeded its size limits; unable to write the block", block);
						continue;
					}

					/* Setup pointers to the blocks */
					blockOffsets[block] = Utils::asBigEndian<uint16_t>((loc_Block - loc_BlockOffsets)>>1);
					dataOffsets[block] = Utils::asBigEndian<uint16_t>((loc_Block+offsetsData.size()*2 - loc_BlockOffsets)>>1);

					/* Write down block offsets and symbol data */
					std::fwrite(offsetsData.data(), offsetsData.size(), sizeof(offsetsData[0]), output);
					std::fwrite(symbolsData.data(), symbolsData.size(), sizeof(symbolsData[0]), output);
				}
			}
		}
		
		/* Finally, write down block offsets table in the header */
		std::fseek(output, loc_BlockOffsets, SEEK_SET);
		std::fwrite(blockOffsets, 0x40, 2, output);
		std::fwrite(dataOffsets, 0x40, 2, output);
	};

};
