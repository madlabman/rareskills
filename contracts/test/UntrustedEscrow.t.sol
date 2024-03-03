// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { UntrustedEscrow } from "../src/UntrustedEscrow.sol";
import { Test, console } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract UntrustedEscrowTest is Utils, Test {
    UntrustedEscrow escrow;
    ERC20Mock token;

    address alice;
    address carol;
    address quinn;

    function setUp() public {
        alice = nextAddress("ALICE");
        carol = nextAddress("CAROL");
        quinn = nextAddress("QUINN");

        escrow = new UntrustedEscrow();
        token = new ERC20Mock();

        vm.prank(alice);
        token.approve(address(escrow), type(uint256).max);
        deal(address(token), alice, 1e5);
    }

    function test_dealWithEscrow() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit UntrustedEscrow.PositionCreated(alice, carol, 0);
        uint256 index = escrow.create({ receiver: carol, token: address(token), amount: 1e5 });

        UntrustedEscrow.Position memory p;
        (p.claimed, p.claimableAt, p.creator, p.receiver, p.token, p.amount) = escrow.positions(index);

        assertEq(p.creator, alice);
        assertEq(p.receiver, carol);
        assertEq(p.token, address(token));
        assertEq(p.amount, 1e5);
        assertEq(p.claimableAt, block.timestamp + escrow.LOCK_INTERVAL());
        assertEq(p.claimed, false);
        assertEq(token.balanceOf(address(escrow)), p.amount);

        vm.prank(carol);
        vm.expectRevert(UntrustedEscrow.PositionIsLocked.selector);
        escrow.claim(index);

        skip(escrow.LOCK_INTERVAL());

        vm.prank(quinn);
        vm.expectRevert(UntrustedEscrow.NotReceiver.selector);
        escrow.claim(index);

        vm.prank(carol);
        vm.expectEmit(true, true, true, true);
        emit UntrustedEscrow.PositionClaimed(alice, carol, index);
        escrow.claim(index);

        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(carol), p.amount);

        vm.prank(carol);
        vm.expectRevert(UntrustedEscrow.PositionIsClaimed.selector);
        escrow.claim(index);

        vm.prank(quinn);
        vm.expectRevert(UntrustedEscrow.NonExistentPosition.selector);
        escrow.claim(index + 1);
    }
}
