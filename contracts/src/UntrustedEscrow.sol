// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UntrustedEscrow {
    using SafeERC20 for IERC20;

    struct Position {
        bool claimed;
        uint40 claimableAt; // The width is reduced to 40 bits for practical reasons.
        address creator;
        address receiver;
        address token;
        uint256 amount;
    }

    uint40 public constant LOCK_INTERVAL = 3 days;

    Position[] public positions;

    event PositionCreated(address indexed creator, address indexed receiver, uint256 index);
    event PositionClaimed(address indexed creator, address indexed receiver, uint256 index);

    error ERC20NotEnoughReceived();
    error ERC20TransferFailed();
    error NonExistentPosition();
    error PositionIsClaimed();
    error PositionIsLocked();
    error NotReceiver();

    /// @return index Index of a new open position.
    function create(address receiver, address token, uint256 amount) external returns (uint256 index) {
        uint256 prevBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 currBalance = IERC20(token).balanceOf(address(this));

        uint256 received = currBalance - prevBalance;
        if (received < amount) {
            revert ERC20NotEnoughReceived();
        }

        index = positions.length;

        positions.push(
            Position({
                creator: msg.sender,
                receiver: receiver,
                token: token,
                amount: amount,
                claimableAt: uint40(block.timestamp) + LOCK_INTERVAL,
                claimed: false
            })
        );

        emit PositionCreated(msg.sender, receiver, index);

        return index;
    }

    function claim(uint256 index) external {
        if (index >= positions.length) {
            revert NonExistentPosition();
        }

        Position memory position = positions[index];

        if (msg.sender != position.receiver) {
            revert NotReceiver();
        }

        if (position.claimed) {
            revert PositionIsClaimed();
        }

        if (block.timestamp < position.claimableAt) {
            revert PositionIsLocked();
        }

        positions[index].claimed = true;
        IERC20(position.token).safeTransfer(msg.sender, position.amount);
        emit PositionClaimed(position.creator, msg.sender, index);
    }
}
