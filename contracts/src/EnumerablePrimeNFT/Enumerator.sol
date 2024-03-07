// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Enumerator {
    IERC721Enumerable public immutable NFT;

    error Undefined();

    constructor(address nft) {
        NFT = IERC721Enumerable(nft);
    }

    function getCountOfPrimeTokens(address holder) external view returns (uint256 primes) {
        uint256 balance = NFT.balanceOf(holder);

        while (balance > 0) {
            unchecked {
                uint256 tokenId = NFT.tokenOfOwnerByIndex(holder, --balance);
                if (isPrime(tokenId)) ++primes;
            }
        }
    }

    function isPrime(uint256 n) public pure returns (bool) {
        if (n == 0) {
            revert Undefined();
        }

        if (n == 1) {
            return false;
        }

        if (n < 4) {
            return true;
        }

        if (n % 2 == 0 || n % 3 == 0) {
            return false;
        }

        uint256 i = 5;
        while (i * i <= n) {
            if (n % i == 0 || n % (i + 2) == 0) {
                return false;
            }
            i += 6;
        }

        return true;
    }
}
