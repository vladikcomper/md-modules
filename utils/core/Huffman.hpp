
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Huffman encoder implementation								*
 * (c) 2017-2018, Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <cstdint>
#include <set>
#include <map>


struct Huffman {

	/* ----------------------- *
	 * Structures declarations *
	 * ----------------------- */

	/* Simple node structure that is used to build a tree */
	struct Node {

		// Constructor: Unlinked Huffman tree node with the data
		Node( const uint8_t _data )
		: data(_data) {
			leaf[0] = leaf[1] = nullptr;	// specify leaves as unlinked (orphant node)
		};

		// Constructor: Marge two specified nodes into a branch (a root for the passed nodes is constructed)
		Node( Node* A, Node* B )
		: data(0) {
			leaf[0] = A;	// link node A to the left leaf
			leaf[1] = B;	// link node B to the right leaf
		};

		// Destructor
		~Node() {
			delete leaf[0];		// destroy node structure in leaf 1
			delete leaf[1];		// destroy node structure in leaf 2
		};

		// Data structure
		uint16_t data;		// character code (or other value) that this node stores
		Node* leaf[2];		// connects the node to the underlying nodes, forming a binary tree
	};

	/* Complete record of Huffman-encoded symbol */
	struct Record {
		
		// Constructor
		Record( uint16_t _code, uint8_t _codeLength, uint8_t _data )
		: code(_code), codeLength(_codeLength), data(_data) {

		};

		// Data structure
		uint16_t code;
		uint8_t codeLength;
		uint8_t data;
	};

	/* Comparator implementation to sort records by code */
	struct sortByCode {
		bool operator () (const Record& A, const Record& B) const {
			return (A.code <= B.code) && (A.codeLength < B.codeLength);
		}
	};

	/* Define type for organized Huffman records */
	typedef std::multiset<Record, sortByCode> 
		RecordSet;


	/* ------------------------ *
	 * Functions implementation *
	 * ------------------------ */

	/**
	 * Recursive subroutine to render Huffman-codes based on pre-generated tree
	 */
	static void
	buildCodes( RecordSet& recordTable, const Node* root, uint16_t code=0, uint8_t codeLength=0 ) {

		if ( root == nullptr ) {
			throw "Error while building codes tree";
		}

		if ( (root->leaf[0] == nullptr ) && (root->leaf[1] == nullptr) ) {	// if this node ends the branch
			recordTable.insert( Record( code, codeLength, root->data ) );
		}
		else {
			buildCodes( recordTable, root->leaf[0], (code<<1)|0, codeLength+1 );
			buildCodes( recordTable, root->leaf[1], (code<<1)|1, codeLength+1 );
		}

	}


	/**
	 * Generates an optimal Huffman-code for each symbol based on the frequency table
	 * @param freqTable Look-up frequency table (e.g. freqTable['A'] corresponds to number of occurances of character 'A')
	 * @return
	 */
	static RecordSet
	encode( const uint32_t freqTable[0x100] ) {

		/* Generate unstructurized queue of Huffman nodes, sorted by the weight */
		std::multimap<uint32_t, Node*> HuffmanQueue;

		for ( int i=0; i<0x100; i++ ) {
			if ( freqTable[i] > 0 ) {
				HuffmanQueue.insert( { freqTable[i], new Node(i) } );
			}
		}

		/* Builds a plain huffman tree */
		while ( HuffmanQueue.size() > 1 ) {

			/* Merge the first two nodes (which are guaranteed to have the least weights) */
			auto least = HuffmanQueue.begin();
			auto preLeast = ++HuffmanQueue.begin();
			Node* merged = new Node( least->second, preLeast->second );

			/* Replaces the affected nodes with a merged one */
			HuffmanQueue.insert( { least->first + preLeast->first, merged } );
			HuffmanQueue.erase( least );
			HuffmanQueue.erase( preLeast );

		}

		/* Build final Huffman codes based on inspecting the tree */
		RecordSet recordTable;
		Huffman::buildCodes( recordTable, HuffmanQueue.begin()->second );

		return recordTable;

	};
	
};