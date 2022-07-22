
#pragma once

#include <cstdint>
#include <string>
#include <map>

/* Base class for the input formats handlers */
struct InputWrapper {

	InputWrapper() { }
	virtual ~InputWrapper() { }

	// Virtual function interface that handles input file parsing
	virtual std::multimap<uint32_t, std::string>
		parse( 
			const char *fileName, 
			uint32_t baseOffset, 
			uint32_t offsetLeftBoundary, 
			uint32_t offsetRightBoundary, 
			uint32_t offsetMask, 
			const char * opts 
		) = 0;

};
