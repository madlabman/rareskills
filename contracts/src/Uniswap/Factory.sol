// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { IPool } from "./Pool.sol";

// The Factory itself is supposed to be deployed behind a proxy.
contract Factory {
    address private immutable __POOL_IMPL;

    constructor(address impl) payable {
        __POOL_IMPL = impl;
    }

    function newPair(string memory name, string memory symbol, address token0, address token1)
        external
        payable
        returns (address pool)
    {
        // The library creates EIP-1167 minimal proxy under the hood.
        pool = Clones.clone(__POOL_IMPL);
        IPool(pool).initialize(name, symbol, token0, token1);
    }
}
