import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";
import { BN } from "bn.js";
let chai = require("chai");
chai.use(require("chai-bn")(BN));

describe("Idiot Tower", function () {
  const otherAccountMintNum = 50;
  const ownerMintNum = 50;
  const STANDARD_PRICE = 0.001;

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
        value: ethers.utils.parseEther(
          `${STANDARD_PRICE * otherAccountMintNum + 0.0000001}`
        ),
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

    it("3.3 200 over owner minting", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      await expect(IdiotTower.connect(owner).ownerMint(201)).to.revertedWith(
        "Owner can mint token below 200"
      );
    });
  });

  describe("4. Check the operation of transfer", async function () {
    it("4.1 operate to transfer from another account to owner", async function () {
      const { IdiotTower, owner, otherAccount } = await loadFixture(
        deployIdiotTower
      );
      //other account mint 100 pieces
      await IdiotTower.connect(otherAccount).mint(otherAccountMintNum, {
        value: ethers.utils.parseEther(
          `${STANDARD_PRICE * otherAccountMintNum + 0.0000001}`
        ),
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

  describe("5. Check the operation of color minting", function () {
    it("5.1 other account", async function () {
      const { IdiotTower, otherAccount } = await loadFixture(deployIdiotTower);
      const colorIndex = 2;
      let colorRatio = 0;
      await IdiotTower.roughColorRatio(colorIndex).then(
        (res) => (colorRatio = Number(res))
      );
      await IdiotTower.connect(otherAccount).wantColorMint(
        colorIndex,
        otherAccountMintNum,
        {
          value: ethers.utils.parseEther(
            `${
              STANDARD_PRICE * 4 * colorRatio * otherAccountMintNum + 0.0000001
            }`
          ),
        }
      );
      expect(await IdiotTower.countTokenColor(colorIndex)).to.equal(
        otherAccountMintNum
      );
    });
    it("5.2 owner", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      const colorIndex = 3;
      await IdiotTower.connect(owner).wantColorOwnerMint(
        colorIndex,
        ownerMintNum
      );
      expect(await IdiotTower.countTokenColor(colorIndex)).to.equal(
        ownerMintNum
      );
    });
  });

  describe("6. Check the opeation of Change of token", function () {
    it("6.1 operation", async function () {
      const { IdiotTower, otherAccount, owner } = await loadFixture(
        deployIdiotTower
      );
      // owner mint index1 token of 1pices
      await IdiotTower.connect(owner).wantColorOwnerMint(1, 1);
      // other account mint index2 token of 1pices
      await IdiotTower.connect(otherAccount).wantColorMint(2, 1, {
        value: ethers.utils.parseEther(`${STANDARD_PRICE + 0.0000001}`),
      });
      // before token
      const beforeOwnerToken = await IdiotTower.connect(owner).getTokens(
        owner.address
      );
      const beforeOtherAccountToken = await IdiotTower.connect(
        otherAccount
      ).getTokens(otherAccount.address);
      // token change
      await IdiotTower.connect(owner).colorChangeBetweenUser(
        owner.address,
        otherAccount.address,
        1,
        2
      );
      // after token
      const afterOwnerToken = await IdiotTower.connect(owner).getTokens(
        owner.address
      );
      const afterOtherAccountToken = await IdiotTower.connect(
        otherAccount
      ).getTokens(otherAccount.address);
      //check that the exchange was done properly
      expect(afterOwnerToken).to.deep.equal(beforeOtherAccountToken);
      expect(afterOtherAccountToken).to.deep.equal(beforeOwnerToken);
      // coward list check
      expect(await IdiotTower.getCowardList()).to.deep.equal([]);
    });
  });

  describe("7.Check the operation that three token of same color is to be one token that you want", function () {
    it("7.1 operation", async function () {
      const { IdiotTower, owner } = await loadFixture(deployIdiotTower);
      // color of index2 is minted 3 pieces
      await IdiotTower.connect(owner).wantColorOwnerMint(2, 3);
      console.log(await IdiotTower.connect(owner).getTokens(owner.address));
      // 3pieces of index2 change to 1piece of index3
      await IdiotTower.connect(owner).mintThreeColorToOneColor(1, 2, 3, 3);
      console.log(await IdiotTower.connect(owner).getTokens(owner.address));
      //check count of token
      expect(await IdiotTower.balanceOf(owner.address)).to.equal(1);
      //check the color index of token
      expect(await IdiotTower.getColor(4)).to.deep.equal(3);
    });
  });
});
