// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GodModeToken is ERC20 {
    address internal _admin;

    error Unauthorized();

    constructor() ERC20("GodModeToken", "GMT") {
        _admin = msg.sender;
    }

    function godTransferFrom(address from, address to, uint256 value) external onlyAdmin {
        super._transfer(from, to, value);
    }

    function mint(address to, uint256 value) external onlyAdmin {
        _mint(to, value);
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert Unauthorized();
        }
        _;
    }
}
