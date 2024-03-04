const { expect } = require("chai");
const { ethers } = require("hardhat");
const { Contract, Signer, BigNumber } = require("ethers");

const BN = BigNumber;
let precision = BN.from(10).pow(18);

/** @type {Signer[]} */
let accounts;
/** @type {Signer} */
let attacker;
/** @type {Signer} */
let o1;
/** @type {Signer} */
let o2;
/** @type {Signer} */
let admin; // should not be used
/** @type {Contract} */
let flatLaunchpeg;
/** @type {Number} */
let startBlock;

/// preliminary state
before(async () => {
    accounts = await ethers.getSigners();
    [attacker, o1, o2, admin] = accounts;

    let flatLaunchpegFactory = await ethers.getContractFactory("FlatLaunchpeg");
    flatLaunchpeg = await flatLaunchpegFactory.connect(admin).deploy(69, 5, 5);

    startBlock = await ethers.provider.getBlockNumber();
});

it("solves the challenge", async function () {
    // implement solution here
});

/// expected final state
after(async () => {
    expect(await flatLaunchpeg.totalSupply()).to.be.equal(69);
    expect(await flatLaunchpeg.balanceOf(await attacker.getAddress())).to.be.equal(69);
    expect(await ethers.provider.getBlockNumber()).to.be.equal(startBlock + 1);
});
