import { expect } from "chai";
import { ethers } from "hardhat";

describe("RevInfotech-Thoritos", function () {
  let Admin;
  let UserOne: any;
  let UserTwo: any;
  let UserThree: any;
  let Thoritos;
  let thoritos: any;

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

});
