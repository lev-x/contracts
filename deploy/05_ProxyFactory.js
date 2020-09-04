const create2 = require("../scripts/create2");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer} = await getNamedAccounts();
  await create2({
    deployer,
    deployments,
    contract: "ProxyFactory",
    salt: "proxy-factory-0",
    updateENS: ["proxy-factory-v0", "proxy-factory"],
  });
};
