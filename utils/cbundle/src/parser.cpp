
/* ------------------------------------------------------------ *
 * Bundle Compilation utility v.2.1								*
 *																*
 * Script parser module											*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

#include <fstream>
#include <iostream>
#include <istream>
#include <ostream>
#include <string_view>
#include <unordered_map>
#define LINE_BUFFER_SIZE 4096

#include <string>
#include <set>

#include <Logger.hpp>

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
		std::istream& file;
		const char * fileName;
		long lineNumber;
	};

	/* Directive definitions */
	const std::unordered_map<std::string, lineType> directives {
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
    bool parseFile(const char* path, std::ostream * out);

	/**
	 * Function to parse line
	 */
	lineData parseLine(parseData * in) {
		// Attempt to read string from the input file
		std::string line;
		if ( in && in->file && std::getline(in->file, line)) {
			in->lineNumber++;
			uint8_t* ptr = reinterpret_cast<uint8_t*>(line.data());

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
						Logger::error("{}:{}: Unknown directive \"#{}\"", in->fileName, in->lineNumber, strDirective);
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
					.content = line
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
					Logger::error("{}: Unexpected end of file while skipping block", in->fileName);
					return error;

				default:
					;
			}

		}

	}

	/**
	 * Function to parse block
	 */
	lineType parseBlock(parseData *in, std::ostream *out, lineType terminator = eof) {

		while (1) {

        	lineData data = parseLine( in );
			if ( data.type == terminator ) return data.type;
			if ( data.type == dir_else ) return data.type;			// stop upon reaching else directive
			if ( data.type == error ) return error;

			// Process line type
			switch (data.type) {
				case raw:
					if (out && *out) {
						out->write(data.content.c_str(), data.content.size());
						out->put('\n');
					}
					else {
						Logger::debug("{}:{}: No valid output specified. Unable to write out line: \"{}\".", in->fileName, in->lineNumber, data.content);
					}
					break;

				case dir_define:
					symbols.insert( data.content );
					Logger::debug("{}:{}: Add \"{}\" to defined symbols list.", in->fileName, in->lineNumber, data.content);
					break;
					
				case dir_undef:
					symbols.erase( data.content );
					Logger::debug("{}:{}: Remove \"{}\" from defined symbols list.", in->fileName, in->lineNumber, data.content);
					break;

				case dir_file:
					{
						std::ofstream innerFile(data.content);
						if (innerFile.fail()) {
							Logger::error("{}:{}: Couldn't open file \"{}\" for writing.", in->fileName, in->lineNumber, data.content);

							return error;
						}

                        lineType lastDirective = parseBlock( in, &innerFile, dir_endf );

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
					Logger::error("{}: Unexpected end of file", in->fileName);
					return error;

				default:
					Logger::error("{}:{}: Unexpected or unsupported directive", in->fileName, in->lineNumber);
					return error;
			}

		}

	}

	/**
	 * Function to parse a file
	 */
	bool parseFile(const char* path, std::ostream * out = nullptr) {
		std::ifstream fileInput;
		std::istream& input = (std::string_view(path) == "-") ? std::cin : (fileInput.open(path), fileInput);
		if (input.fail()) {
			Logger::error("Failed to open \"{}\" for input.", path);
			return false;
		}

		parseData in = {
			.file = input,
			.fileName = path,
			.lineNumber = 0
		};

		// Parsing loop
		lineType lastDirective = parseBlock( &in, out, eof );

		return lastDirective != error;
	}

}
