// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract NFT is Ownable2Step, ERC721Royalty {
    using BitMaps for BitMaps.BitMap;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant BP_MAX = 10_000;
    uint256 public constant PRICE = 1 ether;

    uint256 public totalSupply;

    uint256 public discountPrice;
    bytes32 public merkleRoot;

    BitMaps.BitMap private _minted;

    error EthTransferFailed();
    error MaxSupplyReached();
    error AlreadyMinted();
    error InvalidAmount();
    error InvalidProof();
    error InvalidPercentage();

    constructor(address initialOwner) payable Ownable(initialOwner) ERC721("NFT", "NFT") {
        _setDefaultRoyalty(msg.sender, 250); // 2.5%
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setDiscount(uint256 bp) external onlyOwner {
        if (bp > BP_MAX) {
            revert InvalidPercentage();
        }

        unchecked {
            discountPrice = (BP_MAX - bp) * PRICE / BP_MAX;
        }
    }

    function mint() external payable {
        if (msg.value != PRICE) {
            revert InvalidAmount();
        }

        _mint(msg.sender);
    }

    function mintWithDiscount(bytes32[] calldata proof, uint24 index) external payable {
        if (msg.value != discountPrice) {
            revert InvalidAmount();
        }

        if (_minted.get(index)) {
            revert AlreadyMinted();
        }

        {
            // NOTE: Using sha256 to avoid the second pre-image attack.
            bytes32 leaf = sha256(abi.encode(index, msg.sender));
            _verifyProof(proof, leaf);
        }

        _minted.set(index);
        _mint(msg.sender);
    }

    // Get the roalty value back to the address provided by the owner.
    // TODO: Is it ether, btw?
    function claim(address to) external onlyOwner {
        _sendEth(to, address(this).balance);
    }

    // @dev Indices from 1 to MAX_SUPPLY.
    function _mint(address to) internal {
        unchecked {
            if (++totalSupply > MAX_SUPPLY) {
                revert MaxSupplyReached();
            }
        }
        super._mint(to, totalSupply);
    }

    // For testing purposes mostly.
    function _verifyProof(bytes32[] calldata proof, bytes32 leaf) internal view virtual {
        if (!MerkleProof.verifyCalldata(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }
    }

    function _sendEth(address to, uint256 amount) internal {
        (bool sent,) = to.call{ value: amount }("");
        if (!sent) revert EthTransferFailed();
    }
}
