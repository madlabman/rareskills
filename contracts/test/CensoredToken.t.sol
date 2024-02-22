// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC20Errors } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { CensoredToken } from "../src/CensoredToken.sol";
import { Test, console } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract CensoredTokenTest is Utils, Test {
    CensoredToken token;

    address admin;
    address alice;
    address carol;

    function setUp() public {
        admin = nextAddress("ADMIN");
        alice = nextAddress("ALICE");
        carol = nextAddress("CAROL");

        vm.prank(admin);
        token = new CensoredToken();

        deal(address(token), alice, 1e5);
        deal(address(token), carol, 1e5);
    }

    function test_CensoredToken() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true, address(token));
        emit CensoredToken.UserForbidden(carol);
        token.forbidUser(carol);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, carol));
        token.transfer(carol, 100);

        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, carol));
        token.transfer(alice, 100);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, carol));
        token.mint(carol, 100);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true, address(token));
        emit CensoredToken.UserCleared(carol);
        token.clearUser(carol);

        vm.prank(alice);
        token.transfer(carol, 100);
        assertEq(token.balanceOf(carol), 1e5 + 100);

        vm.prank(carol);
        token.transfer(alice, 100);
        assertEq(token.balanceOf(carol), 1e5);
        assertEq(token.balanceOf(alice), 1e5);

        vm.prank(admin);
        token.mint(carol, 100);
        assertEq(token.balanceOf(carol), 1e5 + 100);
    }
}
