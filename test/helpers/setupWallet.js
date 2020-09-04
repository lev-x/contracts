const {ethers} = require("@nomiclabs/buidler");
const expectToEqual = require("./expectToEqual");
const expectToBeReverted = require("./expectToBeReverted");
const createProxy = require("../../scripts/createProxy");

module.exports = async (config = {}) => {
  const w = config.numberOfWitnesses;
  const signers = await ethers.getSigners();
  const owner = signers[0];
  const witnesses = signers.slice(1, 1 + w);
  const users = signers.slice(1 + w);

  const addrs = [];
  const names = [];
  for (let i = 0; i < w; i++) {
    addrs.push(await witnesses[i].getAddress());
    names.push(ethers.utils.formatBytes32String("witness" + i));
  }
  const wallet = await createProxy(
    config.username || "test",
    await owner.getAddress(),
    addrs,
    names
  );

  await expectToEqual(await owner.getAddress(), wallet.owner());
  await expectToEqual(w, wallet.numberOfWitnesses());
  for (let i = 0; i < w; i++) {
    const address = await witnesses[i].getAddress();
    await expectToEqual(address, wallet.witnesses(i));
    await expectToEqual(
      ethers.utils.formatBytes32String("witness" + i),
      wallet.witnessNames(address)
    );
  }

  const nonWitness = await users[0].getAddress();
  await expectToBeReverted(null, wallet.witnesses(w));
  await expectToEqual(
    ethers.utils.formatBytes32String(""),
    wallet.witnessNames(nonWitness)
  );

  return {wallet, owner, witnesses, users};
};
