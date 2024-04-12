// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondingCurveToken is ERC20 {
    // Both constants make a bonding linear curve `y = mx + c`.
    uint256 public immutable m;
    uint256 public immutable c;

    error InvalidEtherAmount();
    error EthTransferFailed();
    error InvalidCurve();

    constructor(uint256 slope, uint256 interceptor) ERC20("BondingCurveToken", "BCT") {
        if (slope == 0 && interceptor == 0) {
            revert InvalidCurve();
        }

        m = slope;
        c = interceptor;
    }

    receive() external payable {
        revert("Use buy(uint256) function");
    }

    function curve(uint256 x) public view returns (uint256) {
        return m * x + c;
    }

    function sell(uint256 tokens) external {
        uint256 eth = cost({ supply: totalSupply() - tokens, amount: tokens, roundUp: false });
        _burn(msg.sender, tokens);
        _sendEth(msg.sender, eth);
    }

    function buy(uint256 tokens) external payable {
        uint256 eth = cost({ supply: totalSupply(), amount: tokens, roundUp: true });

        if (msg.value != eth) {
            revert InvalidEtherAmount();
        }

        _mint(msg.sender, tokens);
    }

    /// @notice Calculates a total cost paid for the next `amount` tokens starting with `supply`.
    /// @dev Compute as an area of a trapesoid rounded up to the nearest integer.
    function cost(uint256 supply, uint256 amount, bool roundUp) public view returns (uint256) {
        // uint256 nominator = (curve(supply) + curve(supply + amount)) * amount;
        uint256 nominator = (m * (2 * supply + amount) + 2 * c) * amount;
        if (roundUp && nominator % 2 != 0) {
            nominator++;
        }

        return nominator / 2;
    }

    function _sendEth(address to, uint256 amount) internal {
        (bool sent,) = to.call{ value: amount }("");
        if (!sent) revert EthTransferFailed();
    }
}
