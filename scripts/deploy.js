const { ethers, network } = require("hardhat");
const path = require("path");
const fs = require("fs");

(async () => {
  console.log("---------- Deploying to chain %d ----------", network.config.chainId);
  const MultiSigActionsFactory = await ethers.getContractFactory("MultiSigActions");

  let multiSigActions = await MultiSigActionsFactory.deploy(ethers.utils.parseEther("0.00003"));
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
