
/* ------------------------------------------------------------ *
 * Bundle Compilation utility v.1.1								*
 * Script parser module											*
 * (c) 2017-2018, Vladikcomper									*
 * ------------------------------------------------------------	*/

namespace Parser {

	/* Structures and enumerations */
	enum lineType { 
		eof = -2,
		error = -1,

		raw = 0,
		comment,

		dir_define = 0x8,
		dir_undef,
		dir_include,

		dir_ifdef = 0x10,
		dir_ifndef,
		dir_else,
		dir_endif,

		dir_file = 0x20,
		dir_endf

	};
	struct lineData {
		lineType type;
		std::string content;
	};

	/* Directive definitions */
	const std::map<std::string, lineType> directives {
		{ "define",	dir_define	},
		{ "undef",	dir_undef	},
		{ "include",dir_include	},
		{ "ifdef",	dir_ifdef	},
		{ "ifndef",	dir_ifndef	},
		{ "else",	dir_else	},
		{ "endif",	dir_endif	},
		{ "file",	dir_file	},
		{ "endf",	dir_endf	}
	};

	/* Global variables */
	const char * fileName;
	int lineNumber;
	IO::FileInput* input = nullptr;
	IO::FileOutput* output = nullptr;
	std::set<std::string> symbols;

	/* Prototypes */
    void parseFile(const char* path);

	/**
	 * Function to parse line
	 */
	lineData parseLine() {

		const int sBufferSize = 1024;
		uint8_t sBuffer[ sBufferSize ];

		// Attempt to read string from the input file
		if ( input && ( input->readLine( sBuffer, sBufferSize ) >= 0 ) ) {
			lineNumber++;
			uint8_t * ptr = sBuffer;

			// If line is a script directive ...
			if ( *ptr++ == '#' ) {

				// If the next character isn't # (## indicates comment)
				if ( *ptr != '#' ) {
	             	uint8_t * ptr_start;
	
					// Fetch directive name
					ptr_start = ptr++;
	             	while ( *ptr!=' ' && *ptr!=0x00 ) ptr++;
					std::string strDirective( (char*)ptr_start, ptr-ptr_start );
	
					// Fetch directive argument (if present)
					ptr_start = ptr;
					if ( *ptr==' ' ) {
						ptr_start = ++ptr;
	             		while ( *ptr!=' ' && *ptr!=0x00 ) ptr++;
					}
					std::string strArgument( (char*)ptr_start, ptr-ptr_start );

					// Parse directive and return
					auto directiveData = directives.find( strDirective );
					if ( directiveData != directives.end() ) {
						return {
							type: directiveData->second,
							content: strArgument
						};
					}
					else {
						IO::Log( IO::error, "%s:%d: Unknown directive %s", fileName, lineNumber, strDirective.c_str() );
						return {
							type: error,
							content: std::string()
						};
					}

				}
				
				// Otherwise, line is comment ...
				else {
					return {
						type: comment,
						content: std::string()
					};
				}
	
			}

			// Otherwise, return raw line ...
			else {
				return {
					type: raw,
					content: std::string( (char*)sBuffer )
				};
			}
		}
		
		// Otherwise, return eof indicator ...
		else {
			return {
				type: eof,
				content: std::string()
			};
		}
	}

	/**
	 * Function to skip block parsing
	 */
	lineType skipBlock(lineType terminator) {

		while (1) {
        	
        	lineData data = parseLine();
			if ( data.type == terminator ) return data.type;
			if ( data.type == dir_else ) return data.type;			// stop upon reaching else directive

			// Process line type
			switch (data.type) {
				case dir_ifdef:
				case dir_ifndef:
					if ( skipBlock( dir_endif ) != dir_endif )
						skipBlock( dir_endif );
					break;

				case eof:
					IO::Log( IO::error, "%s: Unexpected end of file while skipping block", fileName );
					return eof;

				default:
					;
			}

		}

	}

	/**
	 * Function to parse block
	 */
	lineType parseBlock(lineType terminator = eof) {

		while (1) {

        	lineData data = parseLine();
			if ( data.type == terminator ) return data.type;
			if ( data.type == dir_else ) return data.type;			// stop upon reaching else directive

			// Process line type
			switch (data.type) {
				case raw:
					if ( output ) {
						output->putLine( data.content.c_str() );
					}
					break;

				case dir_define:
					symbols.insert( data.content );
					break;
					
				case dir_undef:
					symbols.erase( data.content );
					break;

				case dir_file:
					{
						void * prev_output = output;
						output = new IO::FileOutput( data.content.c_str(), IO::text );

                        parseBlock( dir_endf );

						delete output;
						output = (IO::FileOutput*)prev_output;
					}
					break;

				case dir_include:
					parseFile( data.content.c_str() );
					break;

				case dir_ifdef:
					{
						lineType lastDirective;
						if ( symbols.find(data.content) != symbols.end() ) {
	    					lastDirective = parseBlock( dir_endif );
	    					if ( lastDirective == dir_else ) skipBlock( dir_endif );
	    				}
						else {
							lastDirective = skipBlock( dir_endif );
	    					if ( lastDirective == dir_else ) parseBlock( dir_endif );
						}
					}
					break;

				case dir_ifndef:
					{
						lineType lastDirective;
						if ( symbols.find(data.content) == symbols.end() ) {
	    					lastDirective = parseBlock( dir_endif );
	    					if ( lastDirective == dir_else ) skipBlock( dir_endif );
	    				}
						else {
							lastDirective = skipBlock( dir_endif );
	    					if ( lastDirective == dir_else ) parseBlock( dir_endif );
						}
					}
					// WARNING! Make sure the next case-section starts with "break" or uncomment
					//break;

				case comment:
					break;

				case eof:
					IO::Log( IO::error, "%s: Unexpected end of file", fileName );
					return eof;

				default:
					IO::Log( IO::error, "%s:%d: Unexpected directive", fileName, lineNumber );
			}

		}

	}

	/**
	 * Function to parse a file
	 */
	void parseFile(const char* path) {

    	// Initialize input stream
		void *prev_input = input;
		int prev_lineNumber = lineNumber;
		input = new IO::FileInput( path, IO::text );

		// Setup variables
		fileName = path;
		lineNumber = 0;

		// Parsing loop
		parseBlock();

		// Terminate input stream
		delete input;
		input = (IO::FileInput*)prev_input;
		lineNumber = prev_lineNumber;
	}

}
