

/* ------------------------------------------------------------ *
 * ConvSym utility version 2.0									*
 * Basic Input / Output wrapper 								*
 * ------------------------------------------------------------	*/

namespace IO {

	/* -------------------- */
	/* Function for logging */
	/* -------------------- */
	
	/* Logging levels */
	enum eLogLevel{ debug, warning, error, fatal }
		LogLevel = warning;

	void Log(eLogLevel level, const char * format, ...) {
		if ( level >= LogLevel ) {
			fputs( (const char*[]){ "", "WARNING: ", "ERROR: ", "FATAL: " }[level], stdout );
			va_list args;
			va_start (args, format);
			vprintf (format, args);
			va_end (args);
			puts("");	// add a newline
		}
	};

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

    	File( const char * path, int mode ): baseOffset(0) {	// Constructor
			const char* modeToCode[] = { "rb", "wb", "r", "w", "r+b", "r+b", "r+", "r+" };
			file = fopen( path, modeToCode[ mode ] );
		}
		
		File(): file(nullptr), baseOffset(0) {

		}
		
		virtual ~File() {	// Destructor
			fclose( file );
		}

		/**
		 * Function to return error state
		 */
		inline bool good() {
			return file!=nullptr;
		}

		/**
		 * Function to set specified offset within the file
		 */
		inline void setOffset( uint32_t offset, eSeekOrigin origin = start ) {
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
		inline void setBaseOffset( uint32_t offset ) {
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

		FileOutput( const char * path, int mode = 0 ) : File( path, write|mode ) {	// Constructor

		};

		inline void writeByte( const uint8_t& byte ) {	// write byte
			fputc( (int)byte, file );
		}

		inline void writeWord( const uint16_t& word ) {	// write word (unmodified)
			fwrite( &word, 2, 1, file );
		}

		inline void writeBEWord( uint16_t word ) {	// write word (LE to BE conversion)
			word = (word<<8) | (word>>8);
			fwrite( &word, 2, 1, file );
		}

		inline void writeLong( const uint32_t& lword ) {	// write long (unmodified)
			fwrite( &lword, 4, 1, file );
		}

		inline void writeBELong( uint32_t lword ) {	// write long (LE to BE conversion)
			lword = (lword<<24) | ((lword<<8)&0xFF0000) | ((lword>>8)&0xFF00) | (lword>>24);
			fwrite( &lword, 4, 1, file );
		}
		
		inline void writeData( const void * buffer, int size ) {	// write series of data
			fwrite( (char*)buffer, 1, size, file );
		};

		inline void putString( const char * str ) {				// put *unformatted* string
			fputs( str, file );
		}

		inline void writeString( const char * format, ...) {	// write a formatted string to file
			va_list args;
			va_start (args, format);
			vfprintf (file, format, args);
			va_end (args);
		}

		inline void writeLine( const char * format, ...) {	// write a formatted string to file
			va_list args;
			va_start (args, format);
			vfprintf (file, format, args);
			va_end (args);
			fputc( '\n', file );
		}

	};

	/* Class for binary file input */
	struct FileInput : File {
	
		FileInput( const char * path, int mode = 0 ) : File( path, read|mode ) {	// Constructor

		};

		inline uint8_t readByte() {		// read byte
			return fgetc( file );
		}

		inline uint16_t readWord() {	// read word (unmodified)
			uint16_t word;
			if ( !fread( &word, 2, 1, file ) ) {
				throw "Failed to read from a binary file";
			}
			return word;
		}

		inline uint16_t readBEWord() {	// read word (LE to BE conversion)
			uint8_t buffer[2];
			if ( !fread( &buffer, 2, 1, file ) ) {
				throw "Failed to read from a binary file";
			}
			return (buffer[0]<<8) + buffer[1];
		}

		inline uint32_t readLong() {	// read long (unmodified)
			uint32_t dword;
			if ( !fread( &dword, 4, 1, file ) ) {
				throw "Failed to read from a binary file";
			}
			return dword;
		}

		inline uint32_t readBELong() {	// read long (LE to BE conversion)
			uint8_t buffer[4];
			if ( !fread( &buffer, 4, 1, file ) ) {
				throw "Failed to read from a binary file";
			}
			return (buffer[0]<<24) + (buffer[1]<<16) + (buffer[2]<<8) + buffer[3];
		}
		
		inline void readData( void* const buffer, int size ) {	// read series of data
			fread( (char*)buffer, 1, size, file );
		};

		inline bool readString( void* const buffer, int size ) {
			return fgets( (char*)buffer, size, file ) != NULL;
		}

	};
	
	/* */

}