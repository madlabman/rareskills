// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is ERC721Enumerable {
    uint256 public constant MAX_SUPPLY = 20;

    error MaxSupplyReached();
    error InvalidTokenId();

    constructor() ERC721("NFT", "NFT") { }

    function mint(uint256 tokenId) public virtual {
        if (totalSupply() >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        if (tokenId > 100) {
            revert InvalidTokenId();
        }

        if (tokenId < 1) {
            revert InvalidTokenId();
        }

        _mint(_msgSender(), tokenId);
    }
}
