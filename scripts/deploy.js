const { ethers, network } = require("hardhat");
const path = require("path");
const fs = require("fs");
const axios = require("axios");

const coinGeckID = {
  56: "binancecoin",
  32520: "bitrise-token",
  311: "omax-token",
  86: "gatechain-token",
  888: "wanchain",
  66: "oec-token"
};

(async () => {
  console.log("---------- Deploying to chain %d ----------", network.config.chainId);
  const MultiSigActionsFactory = await ethers.getContractFactory("MultiSigActions");

  const cgID = coinGeckID[network.config.chainId];
  const { data } = await axios.get(`https://api.coingecko.com/api/v3/simple/price?ids=${cgID}&vs_currencies=usd`);
  const valInUSD = data[cgID].usd;
  const valEther = 10 / valInUSD;

  let multiSigActions = await MultiSigActionsFactory.deploy(ethers.utils.parseEther(valEther.toString()));
  multiSigActions = await multiSigActions.deployed();

  const location = path.join(__dirname, "../actions_addresses.json");
  const fileExists = fs.existsSync(location);

  if (fileExists) {
    const contentBuf = fs.readFileSync(location);
    let contentJSON = JSON.parse(contentBuf.toString());
    contentJSON = {
      ...contentJSON,
      [network.config.chainId]: multiSigActions.address
    };
    fs.writeFileSync(location, JSON.stringify(contentJSON, undefined, 2));
  } else {
    fs.writeFileSync(
      location,
      JSON.stringify(
        {
          [network.config.chainId]: multiSigActions.address
        },
        undefined,
        2
      )
    );
  }
})();
