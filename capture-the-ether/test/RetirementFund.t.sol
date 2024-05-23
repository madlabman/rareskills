// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RetirementFund.sol";

contract RetirementFundTest is Test {
    RetirementFund public retirementFund;

    function setUp() public {
        // Deploy contracts
        retirementFund = (new RetirementFund){value: 1 ether}(address(this));
    }

    function testRetirementFund() public {
        new ExploitContract{value: 1 ether}(retirementFund);
        retirementFund.collectPenalty();
        _checkSolved();
    }

    function _checkSolved() internal {
        assertTrue(retirementFund.isComplete(), "Challenge Incomplete");
    }

    receive() external payable {}
}
