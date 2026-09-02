
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Bitstream helper class										*
 * (c) 2017-2018, 2024 Vladikcomper								*
 * ------------------------------------------------------------	*/

#pragma once

#include <cstdint>

#include <algorithm>
#include <vector>

class BitStream {

	std::vector<uint8_t> buffer;
	uint32_t currentBytePos;
	uint8_t currentBitPos;

public:

	BitStream(): buffer(), currentBytePos(0), currentBitPos(8) {	// Constructor
		buffer.push_back(0x00);
	};

	/**
	 * Returns current offset within the stream
	 */
	inline uint32_t getCurrentPos() {
		return currentBytePos;
	};

	/**
	 * Subroutine to flush the buffer
	 */
	inline void flush() {
		// WARNING! This leaves trailing zero byte even if no bits will be written since!
		buffer.push_back(0x00);
		currentBitPos = 8;
		currentBytePos++;
	};

	/**
	 * Subroutine to push a bit
	 */
	inline void pushBit( unsigned int bit ) {
		if (currentBitPos == 0) { // if the current byte is fully packed, flush it
			flush();
		}
		buffer[currentBytePos] |= (bit << --currentBitPos);
	};

	/**
	 * Pushes a code containing a given number of bits
	 */
	inline void pushCode(uint32_t code, uint8_t codeLength) {
		if (currentBitPos == 0) { // if the current byte is fully packed, flush it
			flush();
		}

		const uint8_t remainingBits = std::max(codeLength - currentBitPos, 0);
		buffer[currentBytePos] |= (code>>remainingBits) << (currentBitPos -= std::min(currentBitPos, codeLength));

		if (remainingBits > 0) {
			pushCode(code & ((1<<remainingBits) - 1), remainingBits);
		}
	};

	/**
	 * Subroutine returns pointer to start of the buffer
	 */
	inline uint8_t* begin() {
		return &(*buffer.begin());
	}

	/**
	 * Subroutine returns pointer to the end of the buffer
	 */
	inline uint8_t* end() {
		return &(*buffer.end());
	}

	/**
	 * Subroutine returns buffer size in bytes
	 */
	inline uint32_t size() {
		return buffer.size();
	}
};
