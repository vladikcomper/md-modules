
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.13									*
 * Output wrapper for the Debug Information format version 2.0	*
 * ------------------------------------------------------------	*/

#include <cassert>
#include <cstdio>
#include <iterator>
#include <cstdint>
#include <stdexcept>
#include <vector>

#include <OptsParser.hpp>
#include <Huffman.hpp>
#include <BitStream.hpp>
#include <Logger.hpp>
#include <Utils.hpp>

#include "OutputWrapper.hpp"


struct Output__Deb2 : public OutputWrapper {

	Output__Deb2(): OutputWrapper(OutputWrapper::PreferredStreamMode::Binary) {};
	~Output__Deb2() {};

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
		constexpr uint16_t magic = Utils::asBigEndian<uint16_t>(0xDEB2);
		std::fwrite(&magic, 2, 1, output);

		/* Allocate space for blocks offsets table */
		auto lastSymbolPtr = symbols.rbegin();
		uint16_t lastBlock = (lastSymbolPtr->offset) >> 16;

		if (lastBlock > 0xFF) {		// blocks index table is limited to $100 entries (which is enough to cover all the 24-bit addressable space)
			Logger::warn("Too many memory blocks to allocate (${:X}), truncating to $100 blocks. Some symbols will be lost.", lastBlock+1);
			lastBlock = 0xFF;
		}

		std::vector<uint32_t> blockOffsets(lastBlock+1);
		const std::size_t blockOffsetsSize = blockOffsets.size() * sizeof(uint32_t);
		const uint16_t huffmanTableOffset = Utils::asBigEndian<uint16_t>(blockOffsetsSize + 2);
		std::fwrite(&huffmanTableOffset, 2, 1, output);			// write relative pointer to the Huffman table
		const uint32_t loc_BlockOffsets = std::ftell(output);	// remember the offset where blocks offset table should start
		std::fwrite(blockOffsets.data(), blockOffsetsSize, 1, output);	// dummy write to reserve space (will be overwritten later)

		/* ------------------------------------------------ */
		/* Generate Huffman-codes and create decoding table */
		/* ------------------------------------------------ */

		Logger::debug("Building an encoding table...");

		/* Generate table of character frequencies based on symbol names */
		uint32_t freqTable[0x100] = { 0 };
		for (const auto& [_, label] : symbols) {
			for (auto& c : label) {
				freqTable[(std::size_t)static_cast<uint8_t>(c)]++;
			}
			freqTable[0x00]++;	// include null-terminator
			// TODOh: Guess whether NULL will be appended to the string of specified length
		}

		/* Generate table of Huffman codes (sorted by code) */
		Huffman::RecordSet codesTable = Huffman::encode(freqTable);

		/* Write down the decoding table */
		const Huffman::Record* characterToRecord[0x100] = { nullptr };	// LUT that links each character to its Huffman-coding record
		{
			std::vector<uint16_t> huffmanTableBuff(codesTable.size() * 2 + 1);
			std::size_t tablePos = 0;
			for (const auto& entry : codesTable) {
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
			struct SymbolRecord { uint16_t offset; uint16_t symbolDataPtr; };
			static_assert(sizeof(SymbolRecord) == 4);

			/* For 64kb block within symbols range */
			for (uint16_t block = 0x00; block <= lastBlock; block++) {
				uint32_t loc_Block = std::ftell(output);
				if (loc_Block & 1) {
					std::fputc(0x00, output);
					loc_Block++;
				}

				BitStream SymbolsHeap;
				std::vector<SymbolRecord> offsetsData;

				/* For every symbol within the block ... */
				for (; (symbolPtr != symbols.cend()) && (symbolPtr->offset>>16) <= block; ++symbolPtr) {
					if ((symbolPtr->offset>>16) < block) {
						continue;
					}

					/* 
					 * For records with the same offsets, fetch only the last or the first processed symbol,
					 * depending "favor last labels" option ...
					 */
					if ((options.favorLastLabels && std::next(symbolPtr) != symbols.end()
							&& std::next(symbolPtr)->offset == symbolPtr->offset) ||
						 (!options.favorLastLabels && symbolPtr != symbols.begin()
							&& std::prev(symbolPtr)->offset == symbolPtr->offset)
					) {
						continue;
					}

					if (SymbolsHeap.getCurrentPos() > 0xFFFF) {
						Logger::warn("Symbols heap for block {:02X} exceeded 64kb limit, no more symbols can be stored in this block.", block);
						break;
					}
					
					else if (offsetsData.size() > 0x3FFF) {
						Logger::warn("Too many symbols in block {:02X}, no more symbols can be stored in this block.", block);
						break;
					}

					else {
						/* Generate symbol structure, that includes offset and encoded symbol text pointer */
						offsetsData.push_back({
							.offset = Utils::asBigEndian<uint16_t>(symbolPtr->offset & 0xFFFF),
							.symbolDataPtr = Utils::asBigEndian<uint16_t>(SymbolsHeap.getCurrentPos())
						});
	
						/* Encode each symbol character with the generated Huffman-codes and store it in the bitsteam */
						for (auto& c : symbolPtr->label) {
							const auto *record = characterToRecord[(std::size_t)static_cast<uint8_t>(c)];
							SymbolsHeap.pushCode( record->code, record->codeLength );
						}
						
						/* Finally, add null-terminator */
						{
							const auto* record = characterToRecord[0x00];
							SymbolsHeap.pushCode(record->code, record->codeLength);
							SymbolsHeap.flush();
						}
					}
				}

				/* Write offsets block and their corresponding encoded symbols heap */
				if (offsetsData.size() > 0) {
					Logger::debug(
						"Block {:02X}: {} bytes (offsets list: {} bytes, symbols heap: {} bytes)",
						block, 2 + offsetsData.size() * 4 + SymbolsHeap.size(), offsetsData.size() * 4, SymbolsHeap.size()
					);

					/* Insert pointer to the end of the list (where heap starts) */
					const uint16_t symbolHeapPtr = Utils::asBigEndian<uint16_t>(2 + offsetsData.size() * 4);
					std::fwrite(&symbolHeapPtr, 2, 1, output);

					/* Write down records that store offset and symbol pointer, then the entire heap */
					std::fwrite(offsetsData.data(), offsetsData.size(), sizeof(offsetsData[0]), output);
					std::fwrite(SymbolsHeap.begin(), SymbolsHeap.size(), 1, output);

					blockOffsets[block] = Utils::asBigEndian<uint32_t>(loc_Block-loc_BlockOffsets);
				}
			}
		}
		
		/* Finally, write down block offsets table in the header */
		std::fseek(output, loc_BlockOffsets, SEEK_SET);
		std::fwrite(blockOffsets.data(), blockOffsetsSize, 1, output);
	};

};
