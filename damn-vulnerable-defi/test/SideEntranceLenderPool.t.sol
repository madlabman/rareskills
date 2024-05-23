// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SideEntranceLenderPool, Exploit} from "../src/SideEntranceLenderPool.sol";

contract SideEntranceLenderPoolTest is Test {
    SideEntranceLenderPool pool;
    uint256 ETHER_IN_POOL = 1_000 ether;

    function setUp() public {
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
    }

    function testExploit() public {
        Exploit exploit = new Exploit(address(pool));
        exploit.doIt();

        assertEq(address(pool).balance, 0);
        assertGt(address(this).balance, ETHER_IN_POOL);
    }

    receive() external payable {}
}
