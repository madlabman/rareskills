// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is Ownable2Step, ERC20 {
    constructor(address initialOwner) payable Ownable(initialOwner) ERC20("RewardToken", "REW") { }

    function mint(address to, uint256 value) external onlyOwner {
        _mint(to, value);
    }
}
