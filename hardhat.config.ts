import { HardhatUserConfig } from "hardhat/types";
import "hardhat-deploy";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks: {
    bsc: {
      url: "http://data-seed-prebsc-1-s2.binance.org:8545/",
      accounts: ["c7f61aa20201ac0640e8a055bd7cbdd5337dab7ee5ef8f6e9f347626486ec8e5"],
    },
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
};

export default config;
