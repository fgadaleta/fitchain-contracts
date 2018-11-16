pragma solidity ^0.4.25;

/**
@title fitchain solidity library
@author Francesco Gadaleta
*/

library FitchainLib {
	/*
    * @notice Concatenate two strings and hash them
    * @param b1 first bytes32 string
    * @param b2 second bytes32 string to concatenate
    * @return bytes hash of concatenated string
    */
    function concatenate2(bytes32 b1, bytes32 b2) internal pure returns (bytes) {
        // make space for 2 bytes32 vars
        bytes memory bytesString = new bytes(2 * 32);
        uint pos;
        // stream b1
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(b1) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[pos] = char;
                pos += 1;
            }
        }
        //stream b2
        for (j=0; j<32; j++) {
            char = byte(bytes32(uint(b2) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[pos] = char;
                pos += 1;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(pos);
        for (uint i=0; i<pos; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }

        return bytesStringTrimmed;
    }

	
    function concatenate3(bytes32 b1, bytes32 b2, bytes32 b3) internal pure returns (bytes) {
      // make space for 3 bytes32 vars
      bytes memory bytesString = new bytes(3 * 32);
      uint pos;
      // stream b1
      for (uint j=0; j<32; j++) {
          byte char = byte(bytes32(uint(b1) * 2 ** (8 * j)));
          if (char != 0) {
              bytesString[pos] = char;
              pos += 1;
          }
      }
      //stream b2
      for (j=0; j<32; j++) {
          char = byte(bytes32(uint(b2) * 2 ** (8 * j)));
          if (char != 0) {
              bytesString[pos] = char;
              pos += 1;
          }
      }
      //stream b3
      for (j=0; j<32; j++) {
          char = byte(bytes32(uint(b3) * 2 ** (8 * j)));
          if (char != 0) {
              bytesString[pos] = char;
              pos += 1;
          }
      }

      bytes memory bytesStringTrimmed = new bytes(pos);
      for (uint i=0; i<pos; i++) {
          bytesStringTrimmed[i] = bytesString[i];
      }

      return bytesStringTrimmed;
    }


    function getSomethingHash(bytes thing_id,
                              bytes32 validation_data_first,
                              bytes32 validation_data_second) public returns (bytes32){
        bytes memory ipfs_address = concatenate2(validation_data_first, validation_data_second);
        string memory s_somethingHash = new string(thing_id.length + ipfs_address.length );
        bytes memory b_somethingHash = bytes(s_somethingHash);
        uint k = 0;
        for (uint i = 0; i < thing_id.length; i++) b_somethingHash[k++] = thing_id[i];
        for (i = 0; i < ipfs_address.length; i++) b_somethingHash[k++] = ipfs_address[i];
        bytes32 somethingHash = keccak256(b_somethingHash);
        return somethingHash;
    }

}
