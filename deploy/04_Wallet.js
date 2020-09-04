const {ethers} = require("@nomiclabs/buidler");
const create2 = require("../scripts/create2");
const getENSGateway = require("../scripts/getENSGateway");
const {utils} = ethers;

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer, witness} = await getNamedAccounts();
  const {address: Storage} = await create2({
    deployer,
    deployments,
    contract: "Storage",
    salt: "storage-0",
  });
  await create2({
    deployer,
    deployments,
    contract: "Wallet",
    libraries: {
      Storage,
    },
    salt: "wallet-0",
    initArgs: [
      (await getENSGateway()).address,
      utils.id("v0"),
      deployer,
      [witness],
      [utils.formatBytes32String("witness")],
    ],
    updateENS: ["wallet-v0", "wallet"],
  });
};
