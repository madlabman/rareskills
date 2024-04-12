// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { RewardToken } from "./RewardToken.sol";
import { NFT } from "./NFT.sol";

contract Staking is IERC721Receiver {
    uint256 public constant REWARD_INTERVAL = 1 days;
    uint256 public constant TOKEN_REWARD = 10;

    mapping(address => uint256[]) public stakedTokens;
    mapping(address => uint256) public claimedAt;

    RewardToken public reward;
    NFT public nft;

    mapping(uint256 => uint256) internal _tokenToStakedTokensIndex;

    error RejectTransfer();
    error InvalidTokenId();

    constructor() payable {
        reward = new RewardToken(address(this));
        nft = new NFT(msg.sender);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != address(nft)) {
            revert RejectTransfer();
        }

        _claim(from);
        _tokenToStakedTokensIndex[tokenId] = stakedTokens[from].length;
        stakedTokens[from].push(tokenId);

        return this.onERC721Received.selector;
    }

    function withdraw(uint256 tokenId) external {
        uint256 tokensCount = stakedTokens[msg.sender].length;
        if (tokensCount == 0) {
            revert InvalidTokenId();
        }

        uint256 index = _tokenToStakedTokensIndex[tokenId];
        if (stakedTokens[msg.sender][index] != tokenId) {
            revert InvalidTokenId();
        }

        _claim(msg.sender);

        delete _tokenToStakedTokensIndex[tokenId];
        if (tokensCount > 1) {
            unchecked {
                uint256 tokenToMove = stakedTokens[msg.sender][tokensCount - 1];
                _tokenToStakedTokensIndex[tokenToMove] = index;
                stakedTokens[msg.sender][index] = tokenToMove;
            }
        }
        stakedTokens[msg.sender].pop();

        nft.transferFrom(address(this), msg.sender, tokenId);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function unclaimed() external view returns (uint256) {
        return _unclaimed(msg.sender);
    }

    function _claim(address user) internal {
        uint256 amount = _unclaimed(user);
        claimedAt[user] = block.timestamp;
        reward.mint(user, amount);
    }

    function _unclaimed(address user) internal view returns (uint256) {
        uint256 tokens = stakedTokens[user].length;
        // Save gas for newcomers.
        if (tokens == 0) {
            return 0;
        }

        uint256 lastClaim = claimedAt[user];
        return tokens * TOKEN_REWARD * (block.timestamp - lastClaim) / REWARD_INTERVAL;
    }
}
