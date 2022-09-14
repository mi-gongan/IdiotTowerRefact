import { ethers } from "hardhat";

async function main() {
  const Token = await ethers.getContractFactory("IdiotTower");
  const IdiotTower = await Token.deploy();

  await IdiotTower.deployed();
  console.log("IdiotTower address:", IdiotTower.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
