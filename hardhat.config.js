require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    local: {
      url: "http://localhost:8545",
      accounts: ["0x9bce709a035954deb674a4538ac91cf90518777c98d608c008a31ef700814ffd"], // Try stealing the funds in this
      chainId: 1337
    },
    bsc_testnet: {
      url: "https://bsctestapi.terminet.io/rpc",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 97
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSC_API_KEY
    }
  }
};
