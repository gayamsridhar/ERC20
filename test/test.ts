import { expect } from "chai";
import { ethers } from "hardhat";
import { Eth }  from "web3-eth";
//import { Web3 }  from "web3";
import web3 from "web3"

describe("RevInfotech-Thoritos", function () {
  let Admin;
  let UserOne: any;
  let UserTwo: any;
  let UserThree: any;
  let Thoritos;
  let thoritos: any;
  const lockReason = '0x4c4f434b31000000000000000000000000000000000000000000000000000000';
  const lockReason2 = '0x4c4f434b32000000000000000000000000000000000000000000000000000000';
  const lockReason3 = '0x4c4f434b33000000000000000000000000000000000000000000000000000000';
  const lockedAmount = 200;
  const lockPeriod = 499;

      beforeEach(async function () {
        [Admin,UserOne,UserTwo,UserThree] = await ethers.getSigners();
        Thoritos = await ethers.getContractFactory("Thoritos");
        thoritos = await Thoritos.deploy();
        await thoritos.deployed();
      });

      it("Thoritos Deployed - Name & Symbol test", async function () {
        console.log("Contract deployed at : ", thoritos.address);
        const name = await thoritos.name();
        console.log("Name of the token : ", name);
        expect(name).to.equal("Thoritos");
        const symbol = await thoritos.symbol();
        console.log("Symbol of the token : ", symbol);
        expect(symbol).to.equal("THOR");
      });

      it('should return the inital supply', async () => {
        const supply = await thoritos.totalSupply();
        console.log("intial supply after contract deployed : ", supply.toNumber());
        expect(supply).to.equal(0);    
      });

      it('Mint By Founder', async () => {
        let supply = await thoritos.totalSupply();
        console.log("intial supply after contract deployed : ", supply.toNumber());
        await thoritos.mint(UserOne.address, 1000);
        supply = await thoritos.totalSupply();
        
        console.log("total supply after minting : ", supply.toNumber());
        expect(supply).to.equal(1000);    
        
        const userOneBal = await thoritos.balanceOf(UserOne.address);
        console.log("userOne Bal after minting : ", userOneBal.toNumber());
        expect(userOneBal).to.equal(1000);
      });

      it('Mint By Non-Founder', async () => {
            // await thoritos.connect(UserOne).mint(UserOne.address, 1000);
            await expect(
              thoritos.connect(UserOne).mint(UserOne.address, 1000)
            ).to.be.revertedWith("not owner");
      });

      it('Mint more than 100000', async () => {
        await expect(
          thoritos.mint(UserOne.address, 100001)
        ).to.be.revertedWith("exceeded the total supply limit");
      });

      it('Burn By Founder', async () => {
        await thoritos.mint(UserOne.address, 1000);
        
        let userOneBal = await thoritos.balanceOf(UserOne.address);
        console.log("userOne Bal after minting : ", userOneBal.toNumber());
        expect(userOneBal).to.equal(1000);

        await thoritos.burn(UserOne.address, 100);

        userOneBal = await thoritos.balanceOf(UserOne.address);
        console.log("userOne Bal after buring 100 tokens : ", userOneBal.toNumber());
        expect(userOneBal).to.equal(900);        
      });

      it('Burn By Non-Founder', async () => {
        await thoritos.mint(UserOne.address, 1000);   
        // await thoritos.burn(UserOne.address, 100);
        await expect(
          thoritos.connect(UserOne).burn(UserOne.address, 1000)
        ).to.be.revertedWith("not owner");        
      });

      it('Has the right total balance for the contract owner', async () => {
        let supply = await thoritos.totalSupply();
        console.log("intial supply after contract deployed : ", supply.toNumber());
        await thoritos.mint(UserOne.address, 1000);
        supply = await thoritos.totalSupply();  
        
        const userOneBal = await thoritos.totalBalanceOf(UserOne.address);
        console.log("totalBalanceOf userOne after minting : ", userOneBal.toNumber());
        expect(userOneBal).to.equal(1000);    
      });
      it('locked tokens from transferable balance', async () => {
        await thoritos.mint(UserOne.address, 1000); 
        let userOneTotalBal = await thoritos.totalBalanceOf(UserOne.address);
        console.log("totalBalanceOf userOne after minting : ", userOneTotalBal.toNumber());
        expect(userOneTotalBal).to.equal(1000);

        await thoritos.connect(UserOne).lock(lockReason, lockedAmount, lockPeriod);
        let userOneBal = await thoritos.balanceOf(UserOne.address);
        console.log("balanceOf userOne after locking 200 tokens : ", userOneBal.toNumber());
        expect(userOneBal).to.equal(userOneTotalBal - lockedAmount);

        let contractBal = await thoritos.balanceOf(thoritos.address);
        console.log("balanceOf contract after locking 200 tokens : ", contractBal.toNumber());
        expect(contractBal).to.equal(lockedAmount);

        let userOneUnlockBal =  await thoritos.getUnlockableTokens(UserOne.address);
        console.log("unlock balanceOf user after locking 200 tokens : ", userOneUnlockBal.toNumber());
        expect(userOneUnlockBal).to.equal(lockedAmount);

        // let currentTimeStamp =  await thoritos.currentTimeStamp();
        // console.log("currentTimeStamp : ", currentTimeStamp.toNumber());
        // let validUntilOf =  await thoritos.validUntilOf(UserOne.address,lockReason);
        // console.log("validUntilOf userOne : ", validUntilOf.toNumber());
      });

      it('reverts locking more tokens via lock function', async () => {
        await thoritos.mint(UserOne.address, 1000); 
        let userOneTotalBal = await thoritos.totalBalanceOf(UserOne.address); 
        await expect(
          thoritos.connect(UserOne).lock(lockReason, userOneTotalBal+1, lockPeriod)
        ).to.be.revertedWith("not enoguh tokens"); 
      });

      it('can increase the number of tokens locked', async () => {
        await thoritos.mint(UserOne.address, 1000); 
        await thoritos.connect(UserOne).lock(lockReason, lockedAmount, lockPeriod);     
        let userOneUnlockBal =  await thoritos.getUnlockableTokens(UserOne.address);
        console.log("userOneUnlockBal after locking 200 tokens : ", userOneUnlockBal.toNumber());
        await thoritos.connect(UserOne).increaseLockAmount(lockReason, lockedAmount);
        userOneUnlockBal =  await thoritos.getUnlockableTokens(UserOne.address);
        console.log("userOneUnlockBal after locking 200 more tokens : ", userOneUnlockBal.toNumber());
        expect(userOneUnlockBal).to.equal(2*lockedAmount);
      });

      it('can unLock tokens', async () => {
        await thoritos.mint(UserOne.address, 1000); 
        await thoritos.connect(UserOne).lock(lockReason, lockedAmount, lockPeriod);
        let userOneUnlockBal =  await thoritos.getUnlockableTokens(UserOne.address);
        expect(userOneUnlockBal).to.equal(lockedAmount); 
        await thoritos.unlock(UserOne.address)
        let userOneBal = await thoritos.balanceOf(UserOne.address);
        expect(userOneBal).to.equal(1000);
      });
});
