
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.0									*
 * Input wrapper for the ASM68K compiler's symbol format		*
 * ------------------------------------------------------------	*/

struct Input__ASM68K_Sym : public InputWrapper {

	Input__ASM68K_Sym() : InputWrapper() { // Constructor

	}

	~Input__ASM68K_Sym() {	// Destructor

	}

	/**
	 * Interface for input file parsing
	 * @param path Input file path
	 * @param baseOffset Base offset for the parsed records (subtracted from the fetched offsets to produce internal offsets)
	 * @param offsetLeftBoundary Left boundary for the calculated offsets
	 * @param offsetRightBoundary Right boundary for the calculated offsets
	 * @return Sorted associative array (map) of found offsets and their corresponding symbol names
	 */
	map<uint32_t, string>
	parse(	const char *fileName,
			uint32_t baseOffset = 0x000000,
			uint32_t offsetLeftBoundary = 0x000000,
			uint32_t offsetRightBoundary = 0x3FFFFF,
			const char * opts = "" ) {

		IO::FileInput input = IO::FileInput( fileName );
		if ( !input.good() ) { throw "Couldn't open input file"; }

		map<uint32_t, string> SymbolMap;
        input.setOffset( 0x0008 );

		// Process data records
        for(;;) {

	        uint32_t offset;
			try {				// read 32-bit label offset
				offset = input.readLong();
			} catch(...) {		// if reading failed, break
				break;
			}

			input.setOffset( 1, IO::current );			// skip 1 byte
			uint8_t	labelLength = input.readByte();

			offset -= baseOffset;
			if ( offset >= offsetLeftBoundary && offset <= offsetRightBoundary ) {	// if offset is within range, add it ...
				char label[ labelLength ];
				input.readData( &label, labelLength );
	            SymbolMap.insert( { offset, string( (const char*)&label, (size_t)labelLength ) } );
			}
			else {
				input.setOffset( labelLength, IO::current );
			}

		};

		return SymbolMap;
	}

};

