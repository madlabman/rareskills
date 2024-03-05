// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CensoredToken is ERC20 {
    mapping(address => uint256) internal _isBanned;
    address internal _admin;

    event UserForbidden(address indexed);
    event UserCleared(address indexed);
    event AdminSet(address indexed);

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

        _isBanned[user] = 1;
        emit UserForbidden(user);
    }

    function clearUser(address user) external onlyAdmin {
        _isBanned[user] = 0;
        emit UserCleared(user);
    }

    function setAdmin(address to) external onlyAdmin {
        _admin = to;
        emit AdminSet(to);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (_isBanned[from] != 0) {
            revert ERC20InvalidSender(from);
        }

        if (_isBanned[to] != 0) {
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
