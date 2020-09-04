const {ethers, deployments} = require("@nomiclabs/buidler");
const {utils} = ethers;
const {expectToEqual, expectToDeepEqual} = require("../helpers");
const getENSGateway = require("../../scripts/getENSGateway");
const approveENSGateway = require("../../scripts/approveENSGateway");

describe("ENSGateway", function () {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should registerSubdomain()", async () => {
    const [owner] = await ethers.getSigners();
    const ensGateway = await getENSGateway();
    await approveENSGateway(ensGateway.address);

    const label = utils.id("test");
    const address = utils.getAddress(
      "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    );

    await expectToEqual(
      ethers.constants.AddressZero,
      ensGateway.ownerOfSubdomain(label)
    );

    await expectToDeepEqual(
      {
        owner: await owner.getAddress(),
        address,
      },
      async () => {
        await ensGateway.registerSubdomain(label, address);
        const resolver = await ethers.getContractAt(
          "Resolver",
          await ensGateway.resolverOfSubdomain(label)
        );
        return {
          owner: await ensGateway.ownerOfSubdomain(label),
          address: await resolver["addr(bytes32)"](
            await ensGateway.subdomainNode(label)
          ),
        };
      }
    );
  });
});
