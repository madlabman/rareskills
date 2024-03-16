// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is ERC721Enumerable {
    uint256 public constant MAX_SUPPLY = 20;

    error MaxSupplyReached();
    error InvalidTokenId();

    constructor() payable ERC721("NFT", "NFT") { }

    function mint() public {
        unchecked {
            uint256 supply = totalSupply();

            if (supply == MAX_SUPPLY) {
                revert MaxSupplyReached();
            }

            _mint(_msgSender(), ++supply);
        }
    }
}
