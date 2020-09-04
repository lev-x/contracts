const {buidlerArguments, ethers, deployments} = require("@nomiclabs/buidler");

module.exports = async () => {
  const {get} = deployments;
  const network = buidlerArguments.network;
  const mock = network === "buidlerevm" || network === "kovan";
  const contract = mock ? "ENSGatewayMock" : "ENSGateway";
  const {abi, address} = await get(contract);
  return await ethers.getContractAt(abi, address);
};
