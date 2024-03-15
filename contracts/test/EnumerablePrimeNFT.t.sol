// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Enumerator } from "../src/EnumerablePrimeNFT/Enumerator.sol";
import { NFT } from "../src/EnumerablePrimeNFT/NFT.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test, console } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract EnumeratorTest is Test {
    using Strings for *;

    Enumerator internal enumerator;
    NFT internal nft;

    function setUp() public {
        nft = new NFT();
        enumerator = new Enumerator(address(nft));
    }

    function test_getCountOfPrimeTokens() public {
        for (uint256 i = 10; i < 14; i++) {
            nft.mint();
        }

        uint256 count = enumerator.getCountOfPrimeTokens(address(this));
        assertEq(count, 2);
    }

    /// forge-config: default.fuzz.runs = 101
    function testFuzz_isPrime(uint256 n) public {
        vm.assume(n > 1);
        vm.assume(n < 100);
        assertEq(enumerator.isPrime(n), _isPrime(n));
    }

    // | Function Name | min | avg | median | max  | # calls |
    // | isPrime       | 312 | 581 | 435    | 1057 | 101     |
    function testGas_isPrime() public view {
        for (uint256 i = 1; i < 101; ++i) {
            enumerator.isPrime(i);
        }
    }

    function _isPrime(uint256 n) internal pure returns (bool) {
        for (uint256 k = 2; k < n; k++) {
            if (n % k == 0) {
                return false;
            }
        }
        return true;
    }
}
