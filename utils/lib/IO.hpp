
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Basic Input / Output wrapper 								*
 * (c) 2017-2018, Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <cstdio>
#include <cstring>
#include <cstdint>


namespace IO {

	/* -------------------------- */
	/* Base class for Binary file */
	/* -------------------------- */

	/* Access mode enumeration */
	enum eMode {
		read = 0,
		write = 1,
		text = 2,
		append = 4
	};

	/* Seeking modes */
	enum eSeekOrigin {
		start = 0,
		end = 1,
		current = 2
	};

	struct File {

		File(const char * path, int mode): baseOffset(0) {	// Constructor
			const char* modeToCode[] = { "rb", "wb", "r", "w", "r+b", "r+b", "r+", "r+" };

			if ((strncmp(path, "-", 2) == 0) && ((mode & 1) == read || (mode & 1) == write)) {
				if ((mode & 1) == read) {
					file = stdin;
				}
				else {
					file = stdout;
				}
			}
			else {
				file = fopen( path, modeToCode[ mode ] );
			}
		}
		
		File(): file(nullptr), baseOffset(0) {

		}
		
		virtual ~File() {	// Destructor
			if (file && (file != stdin) && (file != stdout) && (file != stderr)) {
				fclose( file );
				file = nullptr;
			}
		}

		/**
		 * Function to return error state
		 */
		inline bool good() {
			return file != nullptr;
		}

		/**
		 * Function to set specified offset within the file
		 */
		inline void setOffset(uint32_t offset, eSeekOrigin origin = start) {
			const int originToFlag[] = { SEEK_SET, SEEK_END, SEEK_CUR };
			if ( baseOffset && (origin == start) ) {
				fseek( file, baseOffset + offset, originToFlag[ origin ] );
			}
			else {
				fseek( file, offset, originToFlag[ origin ] );
			}
		}
		
		/**
		 * Function to set the base offset for I/O operations within file
		 */
		inline void setBaseOffset(uint32_t offset) {
			baseOffset = offset;
		}

		/**
		 * Function to get current offset in the file
		 */
		inline uint32_t getCurrentOffset() {
			return ftell( file ) - baseOffset;
		}

	protected:
		FILE* file;
		uint32_t baseOffset;

	};

	/* Class for binary file output */
	struct FileOutput : File {

		FileOutput(const char * path, int mode = 0) : File(path, write|mode) {};

		inline void writeByte(const uint8_t& byte) {	// write byte
			fputc((int)byte, file);
		}

		inline void writeWord(const uint16_t& word) {	// write word (unmodified)
			fwrite(&word, 2, 1, file);
		}

		inline void writeBEWord(uint16_t word) {	// write word (LE to BE conversion)
			word = (word<<8) | (word>>8);
			fwrite(&word, 2, 1, file);
		}

		inline void writeLong(const uint32_t& lword) {	// write long (unmodified)
			fwrite(&lword, 4, 1, file);
		}

		inline void writeBELong(uint32_t lword) {	// write long (LE to BE conversion)
			lword = (lword<<24) | ((lword<<8)&0xFF0000) | ((lword>>8)&0xFF00) | (lword>>24);
			fwrite(&lword, 4, 1, file);
		}
		
		inline void writeData(const void * buffer, int size) {	// write series of data
			fwrite((char*)buffer, 1, size, file);
		};

	};
}