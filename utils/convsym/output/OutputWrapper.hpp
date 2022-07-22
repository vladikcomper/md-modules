#pragma once

#include <map>
#include <cstdint>
#include <string>

#include "../../core/IO.hpp"


/* Base class for the output formats handlers */
struct OutputWrapper {

	OutputWrapper() { }
	virtual ~OutputWrapper() { }

	// Function to setup output
	static IO::FileOutput* setupOutput( const char * fileName, int32_t appendOffset, int32_t pointerOffset ) {

		// If append offset was specified, don't overwrite the contents of file
		if ( appendOffset != 0 ) {

			IO::FileOutput* output = new IO::FileOutput( fileName, IO::append );

			// Make sure IO operation was successful
			if (!output->good()) {
				IO::Log( IO::fatal, "Couldn't open file \"%s\"", fileName );
				throw "IO error";
			}

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
			std::multimap<uint32_t, std::string>& SymbolMap, 
			const char * fileName, 
			uint32_t appendOffset = 0, 
			uint32_t pointerOffset = 0,
			const char * opts = "" 
		) = 0;

};
