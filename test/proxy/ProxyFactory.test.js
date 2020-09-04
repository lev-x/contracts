const {ethers, getNamedAccounts, deployments} = require("@nomiclabs/buidler");
const createProxy = require("../../scripts/createProxy");
const {expectToEqual} = require("../helpers");
const {utils} = ethers;

describe("ProxyFactory", function () {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should createProxy()", async () => {
    const {deployer, witness} = await getNamedAccounts();
    const wallet = await createProxy(
      "test",
      deployer,
      [witness],
      [utils.formatBytes32String("witness")]
    );
    await expectToEqual(utils.id("test"), wallet.label());
    await expectToEqual(deployer, wallet.owner());
    await expectToEqual(1, wallet.numberOfWitnesses());
    await expectToEqual(witness, wallet.witnesses(0));
    await expectToEqual(
      utils.formatBytes32String("witness"),
      wallet.witnessNames(witness)
    );
  });
});
