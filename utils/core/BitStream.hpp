
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Bitstream helper class										*
 * (c) 2017-2018, Vladikcomper									*
 * ------------------------------------------------------------	*/

#include <algorithm>

class BitStream {

	std::vector<uint8_t> * buffer;
	uint32_t currentBytePos;
	uint8_t currentBitPos;

public:

	BitStream(): currentBytePos(0), currentBitPos(8) {	// Constructor
		buffer = new std::vector<uint8_t>;
		buffer->push_back( 0x00 );
	};

	// TODOh: Implement copy constructor and operator =.

	~BitStream() {	// Destructor
		delete buffer;
	};

	/**
	 * Returns current offset within the stream
	 */
	uint32_t getCurrentPos() {
		return currentBytePos;
	};

	/**
	 * Subroutine to flush the buffer
	 */
	void flush() {
		buffer->push_back( 0x00 );
		currentBitPos = 8;
		currentBytePos++;
	};

	/**
	 * Subroutine to push a bit
	 */
	void pushBit( unsigned int bit ) {

		if ( currentBitPos == 0 ) { // if the current byte is fully packed, flush it
			flush();
		}

		(*buffer)[ currentBytePos ] |= (bit << --currentBitPos);
	};

	/**
	 * Subroutine to push a code, containing given number of bits
	 */
	void pushCode( uint32_t code, uint8_t codeLength ) {
		
		if ( currentBitPos == 0 ) { // if the current byte is fully packed, flush it
			flush();
		}

		const uint8_t remainingBits = std::max( codeLength - currentBitPos, 0 );
		(*buffer)[ currentBytePos ] |= (code>>remainingBits) << (currentBitPos -= std::min( currentBitPos, codeLength ));

		if ( remainingBits > 0 ) {
			pushCode( code & ((1<<remainingBits) - 1), remainingBits );
		}

	};

	/**
	 * Subroutine to push a code, containing given number of bits
	 * NOTE: This version doesn't append next byte with the remaining bits if code is too large
	 */
	void pushCodeSpecial( uint32_t code, uint8_t codeLength ) {
		
		if ( currentBitPos == 0 ) {
			return;
		}

		const uint8_t remainingBits = std::max( codeLength - currentBitPos, 0 );
		(*buffer)[ currentBytePos ] |= (code>>remainingBits) << (currentBitPos -= std::min( currentBitPos, codeLength ));

	};

	/**
	 * Subroutine returns pointer to start of the buffer
	 */
	uint8_t* begin() {
		return (uint8_t*)(&(*buffer->begin()));
	}

	/**
	 * Subroutine returns pointer to the end of the buffer
	 */
	uint8_t* end() {
		return (uint8_t*)(&(*buffer->end()));
	}

	/**
	 * Subroutine returns buffer size in bytes
	 */
	uint32_t size() {
		return buffer->size();
	}

};
