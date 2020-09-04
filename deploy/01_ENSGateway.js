const {buidlerArguments} = require("@nomiclabs/buidler");
const create2 = require("../scripts/create2");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer} = await getNamedAccounts();
  const mock =
    buidlerArguments.network === "buidlerevm" ||
    buidlerArguments.network === "kovan";
  const contract = mock ? "ENSGatewayMock" : "ENSGateway";
  await create2({
    deployer,
    deployments,
    contract,
    salt: "ens-gateway-0",
    initArgs: [deployer],
    updateENS: ["ens-gateway-v0", "ens-gateway"],
  });
};
