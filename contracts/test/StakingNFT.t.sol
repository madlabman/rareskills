// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { NFT } from "../src/StakingNFT/NFT.sol";
import { Test } from "forge-std/Test.sol";
import { Utils } from "./utils/Utils.sol";

contract NFTNoProofChecking is NFT {
    constructor(address initialOwner) NFT(initialOwner) { }

    function _verifyProof(bytes32[] calldata proof, bytes32 leaf) internal view override {
        // Do nothing.
    }
}

contract NFTTest is Utils, Test {
    NFTNoProofChecking nft;

    address owner;
    address alice;
    address carol;

    function setUp() public {
        owner = nextAddress("OWNER");
        alice = nextAddress("ALICE");
        carol = nextAddress("CAROL");

        nft = new NFTNoProofChecking(owner);
    }

    function test_mint() public {
        vm.deal(alice, nft.PRICE());
        vm.prank(alice);
        nft.mint{ value: alice.balance }();
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), alice);
    }

    function test_mintMaxSupply() public {
        uint256 maxSupply = nft.MAX_SUPPLY();
        uint256 price = nft.PRICE();

        vm.deal(alice, price * maxSupply);

        for (uint256 i = 0; i < maxSupply; i++) {
            vm.prank(alice);
            nft.mint{ value: price }();
        }

        vm.expectRevert(NFT.MaxSupplyReached.selector);
        vm.deal(alice, price);
        vm.prank(alice);
        nft.mint{ value: price }();
    }

    function test_mintWithDiscount() public {
        _setDisount(5000); // 50%

        uint256 price = nft.PRICE();
        uint256 discountPrice = price / 2;

        vm.deal(alice, discountPrice);
        vm.prank(alice);
        nft.mintWithDiscount{ value: discountPrice }(new bytes32[](0), 0);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), alice);
    }

    function _setDisount(uint256 bp) internal noGasMetering {
        vm.prank(owner);
        nft.setDiscount(bp);
    }
}
