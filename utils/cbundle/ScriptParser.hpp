
/* ------------------------------------------------------------ *
 * Bundle Compilation utility v.1.6								*
 * Script parser module											*
 * (c) 2017-2018, 2020-2021, Vladikcomper						*
 * ------------------------------------------------------------	*/

#define LINE_BUFFER_SIZE 4096

#include <string>
#include <map>
#include <set>

#include "../core/IO.hpp"

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

	struct parseData {
		IO::File * file;
		const char * fileName;
		long lineNumber;

		~parseData() { delete this->file; }
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
	std::set<std::string> symbols;

	/* Prototypes */
    bool parseFile(const char* path, parseData * out);

	/**
	 * Function to parse line
	 */
	lineData parseLine(parseData * in) {

		const int sBufferSize = LINE_BUFFER_SIZE;
		uint8_t sBuffer[ sBufferSize ];

		// Attempt to read string from the input file
		if ( in && in->file && ( ((IO::FileInput*)in->file)->readLine( sBuffer, sBufferSize ) >= 0 ) ) {
			in->lineNumber++;
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
							.type = directiveData->second,
							.content = strArgument
						};
					}
					else {
						IO::Log( IO::error, "%s:%d: Unknown directive \"#%s\"", in->fileName, in->lineNumber, strDirective.c_str() );
						return {
							.type = error,
							.content = std::string()
						};
					}

				}
				
				// Otherwise, line is comment ...
				else {
					return {
						.type = comment,
						.content = std::string()
					};
				}
	
			}

			// Otherwise, return raw line ...
			else {
				return {
					.type = raw,
					.content = std::string( (char*)sBuffer )
				};
			}
		}
		
		// Otherwise, return eof indicator ...
		else {
			return {
				.type = eof,
				.content = std::string()
			};
		}
	}

	/**
	 * Function to skip block parsing
	 */
	lineType skipBlock(parseData * in, lineType terminator) {

		while (1) {
        	
        	lineData data = parseLine( in );
			if ( data.type == terminator ) return data.type;
			if ( data.type == dir_else ) return data.type;			// stop upon reaching else directive
			if ( data.type == error ) return error;

			// Process line type
			switch (data.type) {
				case dir_ifdef:
				case dir_ifndef:
					if ( skipBlock( in, dir_endif ) != dir_endif )
						skipBlock( in, dir_endif );
					break;

				case eof:
					IO::Log( IO::error, "%s: Unexpected end of file while skipping block", in->fileName );
					return error;

				default:
					;
			}

		}

	}

	/**
	 * Function to parse block
	 */
	lineType parseBlock(parseData *in, parseData *out, lineType terminator = eof) {

		while (1) {

        	lineData data = parseLine( in );
			if ( data.type == terminator ) return data.type;
			if ( data.type == dir_else ) return data.type;			// stop upon reaching else directive
			if ( data.type == error ) return error;

			// Process line type
			switch (data.type) {
				case raw:
					if ( out && out->file ) {
						out->lineNumber++;
						((IO::FileOutput*)out->file)->putLine( data.content.c_str() );
					}
					else {
						IO::Log( IO::debug, "%s:%d: No valid output specified. Unable to write out line: \"%s\".", in->fileName, in->lineNumber, data.content.c_str() );
					}
					break;

				case dir_define:
					symbols.insert( data.content );
					IO::Log( IO::debug, "%s:%d: Add \"%s\" to defined symbols list.", in->fileName, in->lineNumber, data.content.c_str() );
					break;
					
				case dir_undef:
					symbols.erase( data.content );
					IO::Log( IO::debug, "%s:%d: Remove \"%s\" from defined symbols list.", in->fileName, in->lineNumber, data.content.c_str() );
					break;

				case dir_file:
					{
						parseData out_inner = {
							.file = new IO::FileOutput( data.content.c_str(), IO::text ),
							.fileName = data.content.c_str(),
							.lineNumber = 0
						};

						if (!out_inner.file->good()) {
							IO::Log( IO::error, "%s:%d: Couldn't open file \"%s\" for writing.", in->fileName, in->lineNumber, data.content.c_str() );
						
							return error;
						}

                        lineType lastDirective = parseBlock( in, &out_inner, dir_endf );

                        if (lastDirective == error) {
                        	return error;
                        }
					}
					break;

				case dir_include:
					{
						bool result = parseFile( data.content.c_str(), out );

						if (!result) {
							return error;
						}
					}

					break;

				case dir_ifdef:
					{
						lineType lastDirective;
						if ( symbols.find(data.content) != symbols.end() ) {
	    					lastDirective = parseBlock( in, out, dir_endif );
	    					if ( lastDirective == dir_else ) {
	    						skipBlock( in, dir_endif );
	    					}
	    				}
						else {
							lastDirective = skipBlock( in, dir_endif );
	    					if ( lastDirective == dir_else ) {
	    						parseBlock( in, out, dir_endif );
	    					}
						}

                        if (lastDirective == error) {
                        	return error;
                        }
					}
					break;

				case dir_ifndef:
					{
						lineType lastDirective;
						if ( symbols.find(data.content) == symbols.end() ) {
	    					lastDirective = parseBlock( in, out, dir_endif );
	    					if ( lastDirective == dir_else ) {
	    						skipBlock( in, dir_endif );
	    					}
	    				}
						else {
							lastDirective = skipBlock( in, dir_endif );
	    					if ( lastDirective == dir_else ) {
	    						parseBlock( in, out, dir_endif );
	    					}
						}

                        if (lastDirective == error) {
                        	return error;
                        }
					}
					break;

				case comment:
					break;

				case eof:
					IO::Log( IO::error, "%s: Unexpected end of file", in->fileName );
					return error;

				default:
					IO::Log( IO::error, "%s:%d: Unexpected or unsupported directive", in->fileName, in->lineNumber );
					return error;
			}

		}

	}

	/**
	 * Function to parse a file
	 */
	bool parseFile(const char* path, parseData * out = nullptr) {

		parseData in = {
			.file = new IO::FileInput( path, IO::text ),
			.fileName = path,
			.lineNumber = 0
		};

		if (!in.file->good()) {
			IO::Log( IO::error, "Failed to open \"%s\" for input.", path );

			return false;
		}

		// Parsing loop
		lineType lastDirective = parseBlock( &in, out, eof );

		return lastDirective != error;
	}

}
