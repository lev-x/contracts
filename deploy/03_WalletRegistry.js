const create2 = require("../scripts/create2");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer} = await getNamedAccounts();
  await create2({
    deployer,
    deployments,
    contract: "WalletRegistry",
    salt: "wallet-registry-0",
    initArgs: [deployer],
    updateENS: ["wallet-registry-v0", "wallet-registry"],
  });
};
