// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { BondingCurveToken } from "../src/BondingCurveToken.sol";
import { Test, console } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract BondingCurveTokenTest is Utils, Test {
    BondingCurveToken token;

    address alice;
    address carol;
    address quinn;

    function setUp() public {
        alice = nextAddress("ALICE");
        carol = nextAddress("CAROL");
        quinn = nextAddress("QUINN");

        vm.deal(alice, 1e5);
    }

    function test_buyTokensXeqY() public {
        token = new BondingCurveToken({ slope: 1, interceptor: 0 });

        // But we can sell 1 token multiple times and it will result in OutOfFund error.
        vm.prank(alice);
        token.buy{ value: 1 }(1);

        vm.prank(alice);
        token.buy{ value: 5000 }(99);

        vm.prank(alice);
        token.buy{ value: 1050 }(10);

        vm.prank(alice);
        token.transfer(carol, 100);

        vm.prank(alice);
        token.transfer(quinn, 10);

        vm.prank(carol);
        token.sell(100);

        vm.prank(quinn);
        token.sell(10);

        assertEq(carol.balance, 6000);
        assertEq(quinn.balance, 50);
        assertEq(token.totalSupply(), 0);
    }

    function test_buyTokens() public {
        token = new BondingCurveToken({ slope: 3, interceptor: 100 });

        vm.prank(alice);
        token.buy{ value: 25000 }(100);

        vm.prank(alice);
        token.buy{ value: 4150 }(10);

        vm.prank(alice);
        token.transfer(carol, 100);

        vm.prank(alice);
        token.transfer(quinn, 10);

        vm.prank(carol);
        token.sell(100);

        vm.prank(quinn);
        token.sell(10);

        assertEq(carol.balance, 28000);
        assertEq(quinn.balance, 1150);
        assertEq(token.totalSupply(), 0);
    }
}
