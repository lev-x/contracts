const getENSGateway = require("./getENSGateway");
const getENSRegistry = require("./getENSRegistry");
const {PublicResolver} = require("@ensdomains/resolver");
const {utils} = ethers;

module.exports = async () => {
  const [owner] = await ethers.getSigners();
  const network = buidlerArguments.network;
  const mock = network === "buidlerevm" || network === "kovan";
  if (mock) {
    return;
  }

  const ensGateway = await getENSGateway();
  const ensRegistry = await getENSRegistry();
  const approved = await ensRegistry.isApprovedForAll(
    await owner.getAddress(),
    ensGateway.address
  );
  if (approved) {
    console.log("ENSRegistry already approved ENSGateway");
  } else {
    await ensRegistry.setApprovalForAll(ensGateway.address, true);
    console.log(
      "ENSRegistry.setApprovalForAll with operator " + ensGateway.address
    );
  }

  const node = utils.solidityKeccak256(
    ["bytes32", "bytes32"],
    [utils.namehash("eth"), utils.id("levx")]
  );

  const resolver = await ethers.getContractAt(
    PublicResolver.abi,
    await ensRegistry.resolver(node)
  );
  const authorised = await resolver.authorisations(
    node,
    await owner.getAddress(),
    ensGateway.address
  );
  if (authorised) {
    console.log("PublicResolver already authorised ENSGateway");
  } else {
    await resolver.setAuthorisation(node, ensGateway.address, true);
    console.log(
      "PublicResolver.setAuthorisation with target " + ensGateway.address
    );
  }
};
