
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.5									*
 * Output formats base controller								*
 * (c) 2017-2018, Vladikcomper									*
 * ------------------------------------------------------------	*/


/* Base class for the output formats handlers */
struct OutputWrapper {

	OutputWrapper() { }
	virtual ~OutputWrapper() { }

	// Function to setup output
	static IO::FileOutput* setupOutput( const char * fileName, int32_t appendOffset, int32_t pointerOffset ) {

		// If append offset was specified, don't overwrite the contents of file
		if ( appendOffset != 0 ) {

			IO::FileOutput* output = new IO::FileOutput( fileName, IO::append );

			// If append mode is specified: append to the end of file
			if ( appendOffset == -1 ) {
				output->setOffset( 0, IO::end );			// move pointer to the end of file ...
				appendOffset = output->getCurrentOffset();
			}
			else {
				output->setOffset( appendOffset );		// move pointer to the specified append offset
			}

			// If pointer offset is specified
			if ( pointerOffset != 0 ) {
				output->setOffset( pointerOffset );
				output->writeBELong( appendOffset );
			}

			// Treat "appendOffset" as the base offset from now on ...
			output->setBaseOffset( appendOffset );
			output->setOffset( 0 );						// move to the start of appending section ...

			return output;

		}

		// Otherwise, discard file contents if exists
		else {
			return new IO::FileOutput( fileName );
		}

	}

	// Virtual function interface that handles generating output data
	virtual void
		parse( 
			std::map<uint32_t, std::string>& SymbolMap, 
			const char * fileName, 
			uint32_t appendOffset = 0, 
			uint32_t pointerOffset = 0,
			const char * opts = "" 
		) = 0;

};


/* Standard output wrappers */
#include "DEB1.hpp"
#include "DEB2.hpp"
#include "Log.hpp"
#include "ASM.hpp"

/* Input wrappers map */
OutputWrapper* getOutputWrapper( const std::string& name ) {

	std::map<std::string, std::function<OutputWrapper*()> >
	wrappersTable {
		{ "deb1",	[]() { return new Output__Deb1();	} },
		{ "deb2",	[]() { return new Output__Deb2();	} },
		{ "log",	[]() { return new Output__Log();	} },
		{ "asm",	[]() { return new Output__Asm();	} }
	};

	auto entry = wrappersTable.find( name );
	if ( entry == wrappersTable.end() ) {
		IO::Log( IO::fatal, "Unknown output format specifier: %s", name.c_str() );
		throw "Bad output format specifier";
	}

	return (entry->second)();

};

