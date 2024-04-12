// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { CommonBase } from "forge-std/Base.sol";

contract Utils is CommonBase {
    bytes32 internal seed = keccak256("seed");

    function nextAddress(string memory label) internal returns (address) {
        bytes32 buf = keccak256(abi.encodePacked(seed));
        address a = address(uint160(uint256(buf)));
        vm.label(a, label);
        seed = buf;
        return a;
    }
}
