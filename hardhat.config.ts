import { HardhatUserConfig } from "hardhat/types";
import "hardhat-deploy";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks: {
    bsc: {
      url: process.env.BSC_RPC_ENDPOINT,
      accounts: [String(process.env.PRIVATE_KEY)],
    },
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
};

export default config;
