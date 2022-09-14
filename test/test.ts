import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";

describe("Idiot Tower", function () {
  const otherAccountMintNum = 100;
  const ownerMintNum = 100;

  async function deployIdiotTower() {
    const Token = await ethers.getContractFactory("IdiotTower");
    const [owner, otherAccount] = await ethers.getSigners();
    const IdiotTower = await Token.deploy();
    await IdiotTower.deployed();

    return { owner, otherAccount, Token, IdiotTower };
  }

  describe("1. Deployment", function () {
    it("1.1 Should set the right owner", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      expect(await IdiotTower.owner()).to.equal(owner.address);
    });

    it("1.2 Should assign the total supply of tokens to the owner", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      const ownerBalance = await IdiotTower.balanceOf(owner.address);
      expect(await IdiotTower.totalSupply()).to.equal(ownerBalance);
    });

    it("1.3 Check the Token Name", async function () {
      const { IdiotTower } = await loadFixture(deployIdiotTower);
      const tokenName = "IdiotTower";
      expect(await IdiotTower.name()).to.equal(tokenName);
    });

    it("1.4 Check the Token Symbol", async function () {
      const { IdiotTower } = await loadFixture(deployIdiotTower);
      const tokenSymbol = "IDIOT";
      expect(await IdiotTower.symbol()).to.equal(tokenSymbol);
    });
  });

  describe("2. Check the wrong access", function () {
    it("2.1 case that owner use the function of mint", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      await expect(IdiotTower.connect(owner).mint(1)).to.revertedWith(
        "Owner can't mint this token"
      );
    });
    it("2.2 case that otherAccount use the function of ownerMint", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      await expect(
        IdiotTower.connect(otherAccount).ownerMint(1)
      ).to.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("3. Check the operation of minting", async function () {
    it("3.1 another account minting", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      //mint 3 pieces
      await IdiotTower.connect(otherAccount).mint(otherAccountMintNum, {
        value: ethers.utils.parseEther("1"),
      });
      expect(await IdiotTower.checkUserHaveMinted(otherAccount.address)).to
        .true;
      // check the balance of other account
      expect(await IdiotTower.balanceOf(otherAccount.address)).to.equal(
        otherAccountMintNum
      );
      // check whether other account is asigned
      expect(await IdiotTower.getUserList()).to.deep.equal([
        otherAccount.address,
      ]);
    });

    it("3.2 owner minting", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      await IdiotTower.connect(owner).ownerMint(ownerMintNum);
      expect(await IdiotTower.checkUserHaveMinted(owner.address)).to.true;
      // check the balance of owner
      expect(await IdiotTower.balanceOf(owner.address)).to.equal(ownerMintNum);
      //check whether owner is assigned
      expect(await IdiotTower.getUserList()).to.deep.equal([owner.address]);
    });
  });

  describe("4. Check the operation of transfer", async function () {
    it("4.1 operate to transfer from another account to owner", async function () {
      const { IdiotTower, owner, otherAccount } = await loadFixture(
        deployIdiotTower
      );
      //other account mint 100 pieces
      await IdiotTower.connect(otherAccount).mint(otherAccountMintNum, {
        value: ethers.utils.parseEther("100"),
      });
      // get the first token of other account
      const tokenIndex = IdiotTower.tokenOfOwnerByIndex(
        otherAccount.address,
        1
      );
      //check the change of the balance after transfer
      await expect(
        IdiotTower.connect(otherAccount).transferFrom(
          otherAccount.address,
          owner.address,
          tokenIndex
        )
      ).to.changeTokenBalances(
        IdiotTower,
        [otherAccount.address, owner.address],
        [-1, 1]
      );
      expect(await IdiotTower.checkUserIsCoward(otherAccount.address)).to.true;
      const cowardList = [otherAccount.address];
      //check whether other account is assigned in coward list
      expect(await IdiotTower.getCowardList()).to.deep.equal(cowardList);
    });
  });
});
