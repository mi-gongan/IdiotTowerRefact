import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";

describe("Idiot Tower", function () {
  const otherAccountMintNum = 2;
  const ownerMintNum = 3;

  async function deployIdiotTower() {
    const [owner, otherAccount] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("IdiotTower");
    const IdiotTower = await Token.deploy();

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
    it("2.1 case that owner use mint", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      await expect(IdiotTower.connect(owner).mint(1)).to.revertedWith(
        "Owner can't mint this token"
      );
    });
    it("2.2 case that otherAccount use ownerMint", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      await expect(
        IdiotTower.connect(otherAccount).ownerMint(1)
      ).to.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("3. Check the operation of minting", async function () {
    it("3.1 another account minting", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      await IdiotTower.connect(otherAccount).mint(otherAccountMintNum, {
        value: ethers.utils.parseEther("0.3"),
      });
    });

    it("3.2 check whether another account has minted", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      expect(await IdiotTower.checkUserHaveMinted(otherAccount.address)).to
        .true;
    });

    it("3.3 check the another account token", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      expect(await IdiotTower.balanceOf(otherAccount.address)).to.equal(
        otherAccountMintNum
      );
    });

    it("3.4 owner minting", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      await IdiotTower.connect(owner).ownerMint(ownerMintNum);
    });

    it("3.5 check whether owner has minted", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      expect(await IdiotTower.checkUserHaveMinted(otherAccount.address)).to
        .true;
    });

    it("3.6 check the owner token", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      expect(await IdiotTower.balanceOf(otherAccount.address)).to.equal(
        otherAccountMintNum
      );
    });

    it("3.7 check the userList", async function () {
      const { IdiotTower, owner, otherAccount } = await loadFixture(
        deployIdiotTower
      );
      expect(await IdiotTower.getUserList()).to.equal([
        owner.address,
        otherAccount.address,
      ]);
    });
  });

  describe("4. Check the operation of transfer", async function () {
    it("4.1 operate to transfer from another account to owner", async function () {});

    it("4.2 check the owner(receiver) token", async function () {});

    it("4.3 check the another account(sender) token", async function () {});

    it("4.4 check whether another account is coward", async function () {});

    it("4.5 check the cowardList", async function () {});
  });
});
