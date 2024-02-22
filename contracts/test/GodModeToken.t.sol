// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { GodModeToken } from "../src/GodModeToken.sol";
import { Test, console } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract GodModeTokenTest is Utils, Test {
    GodModeToken token;

    address admin;
    address alice;
    address carol;

    function setUp() public {
        admin = nextAddress("ADMIN");
        alice = nextAddress("ALICE");
        carol = nextAddress("CAROL");

        vm.prank(admin);
        token = new GodModeToken();

        deal(address(token), alice, 1e5);
    }

    function test_revertIfGodModeTransferNonAdmin() public {
        vm.expectRevert(GodModeToken.Unauthorized.selector);
        vm.prank(carol);
        token.godTransferFrom(alice, carol, 1e5);
    }

    function test_godModeTransfer() public {
        uint256 amount = token.balanceOf(alice);
        assertGt(amount, 0, "Expected alice balance to be non-zero");

        vm.prank(admin);
        token.godTransferFrom(alice, carol, amount);
        assertEq(token.balanceOf(carol), amount);
        assertEq(token.balanceOf(alice), 0);
    }
}
