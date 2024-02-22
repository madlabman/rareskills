// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CensoredToken is ERC20 {
    mapping(address => bool) internal _isBanned;
    address internal _admin;

    event UserForbidden(address);
    event UserCleared(address);
    event AdminSet(address);

    error Unauthorized();
    error ZeroAddress();

    constructor() ERC20("CensoredToken", "CTN") {
        _admin = msg.sender;
        emit AdminSet(msg.sender);
    }

    function mint(address to, uint256 value) external onlyAdmin {
        _mint(to, value);
    }

    function forbidUser(address user) external onlyAdmin {
        if (user == address(0)) {
            revert ZeroAddress();
        }

        _isBanned[user] = true;
        emit UserForbidden(user);
    }

    function clearUser(address user) external onlyAdmin {
        _isBanned[user] = false;
        emit UserCleared(user);
    }

    function setAdmin(address to) external onlyAdmin {
        _admin = to;
        emit AdminSet(to);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (_isBanned[from]) {
            revert ERC20InvalidSender(from);
        }

        if (_isBanned[to]) {
            revert ERC20InvalidReceiver(to);
        }

        super._update(from, to, value);
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert Unauthorized();
        }
        _;
    }
}
