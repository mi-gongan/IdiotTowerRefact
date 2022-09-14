import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  gasReporter: {
    currency: "CHF",
    gasPrice: 21,
    enabled: process.env.REPORT_GAS ? true : false,
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.GOERLI_PRIVATE_KEY || ""],
    },
  },
};

export default config;
