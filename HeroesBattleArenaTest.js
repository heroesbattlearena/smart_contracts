const { time, loadFixture, constants } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
let bigInt = require("big-integer");

async function deployCryptoHunters() {
    const [owner, firstAccount, secondAccount] = await ethers.getSigners();
    let HeroesBattleArena = await ethers.getContractFactory("HeroesBattleArena");
    let url = "https://emerald-far-coral-780.mypinata.cloud/ipfs/QmTRSN4BJqmRJBkWFvtqm9CkyB18CMDHmPijWpguGcezxj/";
    let name = "HEROES BATTLE ARENA";
    HeroesBattleArena = await HeroesBattleArena.deploy(url);
    await HeroesBattleArena.addPart("Random Stone" , 0,"10000000000000000" , "Premium"); // 0.01
    await HeroesBattleArena.addPart("Anubis" , 1 , "2000000000000000000" , "Early"); // 1

    return { HeroesBattleArena, owner,name, firstAccount, secondAccount};
}

describe("HeroesBattleArena", function () {
    describe("Deployment", function () {
        it("Checking initial values of smart contract", async function () {
            const { HeroesBattleArena, name,  owner } = await loadFixture(deployCryptoHunters);
            expect(await HeroesBattleArena.name()).to.be.equal(name);
            expect(await HeroesBattleArena.owner()).to.be.equal(owner.address);
            
        });

        describe("Test mint functionality", function () {
            it("Should buy correctly", async function () {
                const {  HeroesBattleArena, owner,name, firstAccount, secondAccount } = await loadFixture(deployCryptoHunters);
                const estimated = await HeroesBattleArena.getEstimatedMaticAmountForMint(4,1);
                // console.log("estimated : " , estimated);
                // console.log("id : " , (await HeroesBattleArena.getPartById(0)));
                // console.log("id : " , (await HeroesBattleArena.getPartById(1)));
                // console.log("id : " , (await HeroesBattleArena.getPartById(2)));
                const tx =   await HeroesBattleArena.connect(firstAccount).mint('Anubis', 4, { value :  ethers.utils.parseEther("100")});
                // await HeroesBattleArena.connect(firstAccount).mint('Random Stone', 10, { value :  ethers.utils.parseEther("100")});
                // const receipt = await tx.wait()

                // for (const event of receipt.events) {
                //   console.log(`Event ${event.event} with args ${event.args}`);
                // }
                const balance = await ethers.provider.getBalance(HeroesBattleArena.address);
                // console.log("balance",balance);
                expect(await HeroesBattleArena.balanceOf(firstAccount.address, 1)).to.be.equal(4);
                expect(estimated).to.be.equal(balance);
                // expect(await HeroesBattleArena.balanceOf(firstAccount.address, 0)).to.be.equal(10);
            });
        });
    });
});