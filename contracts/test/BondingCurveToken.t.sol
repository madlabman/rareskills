// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

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
        token = deploy({ slope: 1, interceptor: 0 });

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
        token.sell(7);

        vm.prank(quinn);
        token.sell(2);

        vm.prank(quinn);
        token.sell(1);

        assertEq(carol.balance, 6000);
        assertEq(quinn.balance, 49);
        assertEq(token.totalSupply(), 0);
    }

    function test_buyTokens_m3c100() public {
        token = deploy({ slope: 3, interceptor: 100 });

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
        token.sell(7);

        vm.prank(quinn);
        token.sell(2);

        vm.prank(quinn);
        token.sell(1);

        assertEq(carol.balance, 28000);
        assertEq(quinn.balance, 1149);
        assertEq(token.totalSupply(), 0);
    }

    function deploy(uint256 slope, uint256 interceptor) internal noGasMetering returns (BondingCurveToken) {
        return new BondingCurveToken(slope, interceptor);
    }
}
