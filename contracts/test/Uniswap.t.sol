// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Pool, ICallee } from "../src/Uniswap/Pool.sol";
import { Test, console } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract MineERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    // Just to get rid of approval calls.
    function allowance(address, address) public pure override returns (uint256) {
        return type(uint256).max;
    }

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }
}

contract Borrower is ICallee {
    event Callback();

    function borrow(address pool, uint256 amount0, uint256 amount1, bytes calldata data) external {
        Pool(pool).flashLoan(amount0, amount1, data);
    }

    function callback(bytes calldata /* data */ ) external payable {
        emit Callback();
    }
}

contract ReentrantBorrower is ICallee {
    address private _pool;

    constructor(address pool) {
        _pool = pool;
    }

    function borrow(uint256 amount0, uint256 amount1, bytes calldata data) external {
        Pool(_pool).flashLoan(amount0, amount1, data);
    }

    function callback(bytes calldata /* data */ ) external payable {
        Pool(_pool).flashLoan(1, 1, ""); // should revert
    }
}

contract UniswapTest is Utils, Test {
    MineERC20 token0;
    MineERC20 token1;

    Pool pool;
    Borrower borrower;
    ReentrantBorrower rBorrower;

    address alice;
    address carol;

    function setUp() public {
        alice = nextAddress("ALICE");
        carol = nextAddress("CAROL");

        token0 = new MineERC20("X", "X");
        token1 = new MineERC20("Y", "Y");

        pool = new Pool();
        pool.initialize("UniXY", "UniXY", address(token0), address(token1));

        borrower = new Borrower();
        rBorrower = new ReentrantBorrower(address(pool));
    }

    function test_UniswapSwap() public {
        token0.mint(address(this), 10_000);
        token1.mint(address(this), 40_000_000);

        pool.deposit(token0.balanceOf(address(this)), token1.balanceOf(address(this)));

        uint256 token1Amount = 2_111_598;
        token1.mint(address(this), token1Amount);

        pool.swap(0, token1Amount, type(uint256).max);
        assertApproxEqAbs(token0.balanceOf(address(this)), 500, 1);
    }

    function test_UniswapFirstDeposit() public {
        token0.mint(address(this), 10_000);
        token1.mint(address(this), 40_000_000);

        pool.deposit(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
        assertEq(pool.balanceOf(address(this)), 632_455);
    }

    function test_UniswapFirstDepositorAttack() public {
        token0.mint(address(this), 1);
        token1.mint(address(this), 1);

        pool.deposit(1, 1);

        token0.mint(alice, 100);
        token1.mint(alice, 100);

        vm.prank(alice);
        pool.deposit(100, 100);

        assertGt(pool.balanceOf(alice), 0, "attack succeeded");
    }

    function test_UniswapWithdraw() public {
        {
            token0.mint(alice, 1e15);
            token1.mint(alice, 1e17);

            token0.mint(carol, 1e13);
            token1.mint(carol, 1e15);
        }

        vm.prank(alice);
        pool.deposit(1e15, 1e17);

        vm.prank(carol);
        pool.deposit(1e13, 1e13);

        vm.prank(carol);
        pool.withdraw(0, 0, 0);

        vm.prank(alice);
        pool.withdraw(0, 0, 0);

        assertApproxEqAbs(token0.balanceOf(alice), 1e15, 1, "err: token0(alice)");
        assertApproxEqAbs(token1.balanceOf(alice), 1e17, 1, "err: token1(alice)");

        assertApproxEqAbs(token0.balanceOf(carol), 1e13, 1, "err: token0(carol)");
        assertApproxEqAbs(token1.balanceOf(carol), 1e15, 1, "err: token1(carol)");
    }

    function test_UniswapFlashLoan() public {
        {
            token0.mint(carol, 1000);
            token1.mint(carol, 1000);
            vm.prank(carol);
            pool.deposit(1000, 1000);
        }

        token0.mint(address(borrower), 3); // mint fee to repay loan

        {
            vm.expectEmit(true, true, true, true, address(token0));
            emit IERC20.Transfer(address(pool), address(borrower), 1000);

            vm.expectEmit(true, true, true, true, address(token1));
            emit IERC20.Transfer(address(pool), address(borrower), 100);

            vm.expectEmit(true, true, true, true, address(borrower));
            emit Borrower.Callback();

            borrower.borrow(address(pool), 1000, 100, "");
        }

        assertEq(pool.reserve0(), 1003, "loan wasn't repaid?");
        assertEq(pool.reserve1(), 1000, "loan wasn't repaid?");
    }

    function test_UniswapFlashLoanNonReentrant() public {
        {
            token0.mint(address(this), 1000);
            token1.mint(address(this), 1000);
            pool.deposit(1000, 1000);
        }

        token0.mint(address(rBorrower), 100); // mint fee to repay loan

        vm.expectRevert(Pool.Reentrancy.selector);
        rBorrower.borrow(100, 100, "");

        assertEq(pool.lock(), false);
    }

    function test_UniswapTWAP() public {
        uint256 delta = 100_500;

        {
            token0.mint(address(this), 1000);
            token1.mint(address(this), 2000);

            vm.warp(10);
            pool.deposit(250, 500);

            vm.warp(10 + delta);
            pool.deposit(750, 1500);
        }

        uint256 price;

        price = pool.cumulativePrice0() / delta;
        assertEq(price, 1 << 113); // Q112.112(2.0)

        price = pool.cumulativePrice1() / delta;
        assertEq(price, 1 << 111); // Q112.112(0.5)
    }
}
