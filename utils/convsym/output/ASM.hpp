
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.0									*
 * Output wrapper for assembly file with equates				*
 * ------------------------------------------------------------	*/


struct Output__Asm : public OutputWrapper {

public:

	Output__Asm() {	// Constructor

	};

	~Output__Asm() {	// Destructor

	};

	/**
	 * Main function that generates the output
	 */
	void
	parse(	map<uint32_t, string>& SymbolList,
			const char * fileName,
			uint32_t appendOffset = 0,
			uint32_t pointerOffset = 0,
			const char * opts = "" ) {

		const char * lineFormat = *opts ? opts : "%s:\tequ\t$%X";
		IO::FileOutput output = IO::FileOutput( fileName );

		for ( auto symbol : SymbolList ) {
			output.writeLine( lineFormat, symbol.second.c_str(), symbol.first );
		}

	}

};
