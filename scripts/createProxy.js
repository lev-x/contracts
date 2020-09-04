const {buidlerArguments, ethers, deployments} = require("@nomiclabs/buidler");
const {utils} = ethers;

module.exports = async (label, owner, witnessAddrs, witnessNames) => {
  const network = buidlerArguments.network;
  const ENSGateway = await deployments.get(
    network === "mainnet" ? "ENSGateway" : "ENSGatewayMock"
  );
  const ProxyFactory = await deployments.get("ProxyFactory");
  const Wallet = await deployments.get("Wallet");

  const proxyFactory = await ethers.getContractAt(
    ProxyFactory.abi,
    ProxyFactory.address
  );
  const implementation = await ethers.getContractAt(Wallet.abi, Wallet.address);

  const signer = (await ethers.getSigners())[0];
  const salt = utils.id(label);
  const initializeData = implementation.interface.encodeFunctionData(
    "initialize",
    [ENSGateway.address, utils.id(label), owner, witnessAddrs, witnessNames]
  );
  const message = utils.arrayify(
    utils.solidityKeccak256(
      ["address", "address", "bytes32", "bytes"],
      [
        proxyFactory.address,
        implementation.address,
        salt,
        utils.arrayify(initializeData),
      ]
    )
  );
  const signature = await signer.signMessage(message);
  const tx = await proxyFactory.createProxy(
    implementation.address,
    salt,
    initializeData,
    signature
  );
  const receipt = await tx.wait();
  const event = receipt.events.find((event) => event.event === "ProxyCreated");
  const address = event.args.proxy;

  return await ethers.getContractAt(Wallet.abi, address);
};
