const {
  buidlerArguments,
  ethers,
  getNamedAccounts,
  deployments,
} = require("@nomiclabs/buidler");
const {Resolver} = require("@ensdomains/resolver");
const compareAddresses = require("./compareAddresses");
const {utils} = ethers;

module.exports = async (subdomain, address) => {
  const {deployer} = await getNamedAccounts();
  const {execute, read} = deployments;
  const network = buidlerArguments.network;
  const mock = network === "buidlerevm" || network === "kovan";
  const contract = mock ? "ENSGatewayMock" : "ENSGateway";
  const label = utils.id(subdomain);

  const owner = await read(contract, {}, "ownerOfSubdomain", label);
  if (owner === ethers.constants.AddressZero) {
    await execute(
      contract,
      {
        from: deployer,
        log: true,
      },
      "registerSubdomain",
      label,
      address
    );
  } else {
    const resolver = await ethers.getContractAt(
      Resolver.abi,
      await read(contract, {}, "resolverOfSubdomain", label)
    );
    const node = await read(contract, {}, "subdomainNode", label);
    const resolved = await resolver["addr(bytes32)"](node);
    if (!(await compareAddresses(resolved, address))) {
      await resolver["setAddr(bytes32,address)"](node, address);
    }
  }
  console.log("  " + subdomain + " => " + address);
};
