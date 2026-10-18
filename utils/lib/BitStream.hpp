
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Bitstream helper class										*
 * (c) 2017-2026 Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <cstdint>

#include <algorithm>
#include <vector>

struct BitStream {

	std::vector<uint8_t> buffer;
	int bitPos;

	BitStream(): buffer(), bitPos(0) { };

	/**
	 * Subroutine to finalize the current byte
	 */
	inline void flushByte() {
		bitPos = 0;
	};

	/**
	 * Pushes a code containing a given number of bits
	 */
	inline void pushBits(uint32_t code, int codeLength) {
		while (codeLength > 0) {
			if (bitPos == 0) {
				bitPos = 8;
				buffer.push_back(0x00);
			}

			const int remainingBits = std::max(codeLength - bitPos, 0);
			buffer.back() |= (code >> remainingBits) << (bitPos -= std::min(bitPos, codeLength));

			codeLength = remainingBits;
			code &= ((1 << remainingBits) - 1);
		}
	};
};
