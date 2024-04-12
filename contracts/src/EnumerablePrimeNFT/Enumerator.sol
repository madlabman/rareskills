// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Enumerator {
    IERC721Enumerable public immutable NFT;

    error Undefined();

    constructor(address nft) payable {
        NFT = IERC721Enumerable(nft);
    }

    function getCountOfPrimeTokens(address holder) external view returns (uint256 primes) {
        uint256 balance = NFT.balanceOf(holder);

        while (balance != 0) {
            unchecked {
                uint256 tokenId = NFT.tokenOfOwnerByIndex(holder, --balance);
                primes += isPrime(tokenId); // isPrime returns 1 if prime, 0 if not;
            }
        }
    }

    function isPrime(uint256 n) public pure returns (uint256) {
        if (n == 0) {
            revert Undefined();
        }

        if (n == 1) {
            return 0;
        }

        if (n < 4) {
            return 1;
        }

        if (n & 1 == 0) {
            return 0;
        }

        if (n % 3 == 0) {
            return 0;
        }

        uint256 i = 5;

        unchecked {
            while (i * i <= n) {
                if (n % i == 0) {
                    return 0;
                }

                if (n % (i + 2) == 0) {
                    return 0;
                }

                i += 6;
            }
        }

        return 1;
    }
}
