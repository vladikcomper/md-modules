
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.5.2								*
 * Output wrapper for the Debug Information format version 2.0	*
 * ------------------------------------------------------------	*/


struct Output__Deb2 : public OutputWrapper {

public:

	Output__Deb2() {	// Constructor

	};

	~Output__Deb2() {	// Destructor

	};

	/**
	 * Main function that generates the output
	 */
	void
	parse(	std::map<uint32_t, std::string>& SymbolList,
			const char * fileName,
			uint32_t appendOffset = 0,
			uint32_t pointerOffset = 0,
			const char * opts = "" ) {

		IO::FileOutput output = *OutputWrapper::setupOutput( fileName, appendOffset, pointerOffset );

		/* Write format version token */
		output.writeBEWord( 0xDEB2 );

		/* Allocate space for blocks offsets table */
		auto lastSymbolPtr = SymbolList.rbegin();
		uint16_t lastBlock = (lastSymbolPtr->first) >> 16;
		uint32_t blockOffsets [ lastBlock+1 ] = { 0 };

		output.writeBEWord( sizeof(blockOffsets) + 2 );			// write relative pointer to the Huffman table
		uint32_t loc_BlockOffsets = output.getCurrentOffset();	// remember the offset where blocks offset table should start
		output.setOffset( sizeof(blockOffsets), IO::current );	// reserve space to write down offsets table later

		/* ------------------------------------------------ */
		/* Generate Huffman-codes and create decoding table */
		/* ------------------------------------------------ */

		IO::Log( IO::debug, "Building an encoding table...");

		/* Generate table of character frequencies based on symbol names */
		uint32_t freqTable[0x100] = { 0 };
		for ( auto& Symbol : SymbolList ) {
			for ( auto& Character : Symbol.second ) {
				freqTable[ (int)Character ]++;
			}
			freqTable[ 0x00 ]++;	// include null-terminator
			// TODOh: Guess whether NULL will be appended to the string of specified length
		}

		/* Generate table of Huffman codes (sorted by code) */
		Huffman::RecordSet codesTable = Huffman::encode( freqTable );

		/* Write down the decoding table */
		const Huffman::Record* characterToRecord[0x100] = { nullptr };	// LUT that links each character to its Huffman-coding record
		for ( auto& entry : codesTable ) {
			characterToRecord[ entry.data ] = &entry;	// assign character this Huffman::Record entity
			output.writeBEWord( entry.code );			// write Huffman-code
			output.writeByte( entry.codeLength );		// write Huffman-code length (in bits)
			output.writeByte( entry.data );				// write down original character
		}
		output.writeWord( -1 );			// write 0xFFFF at the end of Huffman-table to stop searching and cause error

		/* ------------------------------------- */
		/* Generate per block symbol information */
		/* ------------------------------------- */

		{
			IO::Log( IO::debug, "Generating symbol data blocks...");

			auto SymbolPtr = SymbolList.begin();
			struct SymbolRecord { uint16_t offset; uint16_t symbolDataPtr; };

			/* For 64kb block within symbols range */
			for ( uint16_t block = 0x00; block <= lastBlock; block++ ) {

            	/* Align block on even address */
            	if ( output.getCurrentOffset() & 1 ) {
                	output.writeByte( 0x00 );
				}

				uint32_t loc_Block = output.getCurrentOffset();	// remember offset, where this block starts ...

				BitStream SymbolsHeap;
				std::vector<SymbolRecord> offsetsData;

            	/* For every symbol within the block ... */
            	for ( ; block == (SymbolPtr->first>>16) && (SymbolPtr != SymbolList.cend()); ++SymbolPtr ) {

					if ( SymbolsHeap.getCurrentPos() > 0xFFFF ) {
						IO::Log( IO::error,"Symbols heap for block %02X exceeded 64kb limit, no more symbols can be stored in this block.", block );
						break;
					}
					
					else if ( offsetsData.size() > 0x3FFF ) {
						IO::Log( IO::error, "Too many symbols in block %02X, no more symbols can be stored in this block.", block );
						break;
					}

					else {

						/* Generate symbol structure, that includes offset and encoded symbol text pointer */
						offsetsData.push_back(
							(SymbolRecord) {
								.offset = (uint16_t) (SymbolPtr->first & 0xFFFF),
								.symbolDataPtr = (uint16_t) SymbolsHeap.getCurrentPos()
							}
						);
	
						/* Encode each symbol character with the generated Huffman-codes and store it in the bitsteam */
						for ( auto& Character : SymbolPtr->second ) {
							auto *record = characterToRecord[ (int)Character ];
							SymbolsHeap.pushCode( record->code, record->codeLength );
						}
						
						/* Finally, add null-terminator */
						{
							auto *record = characterToRecord[ 0x00 ];
							SymbolsHeap.pushCode( record->code, record->codeLength );
							SymbolsHeap.flush();
						}
					}

				}

				/* Write offsets block and their corresponding encoded symbols heap */
				if ( offsetsData.size() > 0 ) {

					IO::Log( IO::debug,
						"Block %02X: %d bytes (offsets list: %d bytes, symbols heap: %d bytes)",
						block, 2+offsetsData.size()*4+SymbolsHeap.size(), offsetsData.size()*4, SymbolsHeap.size()
					);

					/* Insert pointer to the end of the list (where heap starts) */
					output.writeBEWord( 2 + offsetsData.size()*4 );		// write down offset

					/* Write down records that store offset and symbol pointer */
					for ( auto& entry : offsetsData ) {
						output.writeBEWord( entry.offset );		// write down offset
						output.writeBEWord( entry.symbolDataPtr );	// write down expected relative pointer to the heap
					}

					output.writeData( SymbolsHeap.begin(), SymbolsHeap.size() );
					blockOffsets[block] = swap32( (loc_Block-loc_BlockOffsets) );

				}
			}
		}
		
		/* Finally, write down block offsets table in the header */
		output.setOffset( loc_BlockOffsets, IO::start );
		output.writeData( blockOffsets, sizeof(blockOffsets) );

	};

};
