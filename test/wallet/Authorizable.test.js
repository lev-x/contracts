const {ethers, deployments} = require("@nomiclabs/buidler");
const {
  sign,
  setupWallet,
  getAddress,
  increaseTime,
  expectToBeReverted,
  expectToEqual,
  expectLastExecutedAt,
} = require("../helpers");

const setupAuthorizable = async (config = {}) => {
  const {wallet, owner, witnesses, users} = await setupWallet(config);

  const transferOwnership = async (account, witnessIndexesToSign = []) => {
    const address = await getAddress(account);
    const signatures = [];
    const message = await wallet.transferOwnershipHash(address);
    for (const i of witnessIndexesToSign) {
      signatures.push(await sign(witnesses[i], message));
    }
    const tx = await wallet.transferOwnership(address, ["0x", signatures]);
    await expectLastExecutedAt(wallet, "transferOwnership", tx.blockNumber);
    return tx;
  };

  const addWitness = async (account, name, accountToSign) => {
    const address = await getAddress(account);
    const nameBytes = ethers.utils.formatBytes32String(name);
    const message = await wallet.addWitnessHash(address, nameBytes);
    const signature = await sign(accountToSign, message);
    const tx = await wallet.addWitness(address, nameBytes, [signature, []]);
    await expectLastExecutedAt(wallet, "addWitness", tx.blockNumber);
    return tx;
  };

  const removeWitness = async (account, accountToSign) => {
    const address = await getAddress(account);
    const message = await wallet.removeWitnessHash(address);
    const signature = await sign(accountToSign, message);
    const tx = await wallet.removeWitness(address, [signature, []]);
    await expectLastExecutedAt(wallet, "removeWitness", tx.blockNumber);
    return tx;
  };

  return {
    wallet,
    owner,
    witnesses,
    users,
    transferOwnership,
    addWitness,
    removeWitness,
  };
};

describe("Authorizable", function () {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should transferOwnership() with 1 witness", async () => {
    const {
      wallet,
      owner,
      users,
      witnesses,
      transferOwnership,
    } = await setupAuthorizable({
      numberOfWitnesses: 1,
    });

    await expectToBeReverted(
      "wallet-cannot-be-owner",
      transferOwnership(wallet, [0])
    );
    await expectToBeReverted(
      "witness-cannot-be-owner",
      transferOwnership(witnesses[0], [0])
    );
    await expectToBeReverted("already-owner", transferOwnership(owner, [0]));

    await expectToEqual(await users[0].getAddress(), async () => {
      await transferOwnership(users[0], [0]);
      return await wallet.owner();
    });
  });

  it("Should transferOwnership() with 2 witnesses", async () => {
    const {wallet, owner, users, transferOwnership} = await setupAuthorizable({
      numberOfWitnesses: 2,
    });

    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [])
    );
    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [0])
    );
    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [1])
    );
    await expectToBeReverted("already-owner", transferOwnership(owner, [0, 1]));

    await expectToEqual(await users[0].getAddress(), async () => {
      await transferOwnership(users[0], [0, 1]);
      return await wallet.owner();
    });
  });

  it("Should transferOwnership() with 3 witnesses", async () => {
    const {wallet, owner, users, transferOwnership} = await setupAuthorizable({
      numberOfWitnesses: 3,
    });

    const expectOwnershipTransferred = async (
      newOwner,
      witnessIndexesToSign
    ) => {
      await expectToEqual(await newOwner.getAddress(), async () => {
        await transferOwnership(newOwner, witnessIndexesToSign);
        return await wallet.owner();
      });
    };

    await expectToBeReverted(
      "already-owner",
      transferOwnership(owner, [0, 1, 2])
    );
    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [])
    );
    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [0])
    );
    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [1])
    );
    await expectToBeReverted(
      "more-signatures-required",
      transferOwnership(users[0], [2])
    );

    await expectOwnershipTransferred(users[0], [0, 1]);
    await expectOwnershipTransferred(users[1], [0, 2]);
    await expectOwnershipTransferred(users[2], [1, 2]);
    await expectOwnershipTransferred(users[3], [0, 1, 2]);
  });

  it("Should addWitness()", async () => {
    const {wallet, owner, users, addWitness} = await setupAuthorizable({
      numberOfWitnesses: 1,
    });

    await expectToEqual(
      ethers.utils.formatBytes32String("witness1"),
      async () => {
        await addWitness(users[0], "witness1", owner);
        return await wallet.witnessNames(await users[0].getAddress());
      }
    );
    await expectToEqual(2, wallet.numberOfWitnesses);

    const securityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("addWitness")
    );
    await increaseTime(securityPeriod.time);

    await expectToBeReverted(
      "cannot-add-wallet",
      addWitness(wallet, "witness2", owner)
    );
    await expectToBeReverted(
      "cannot-add-owner",
      addWitness(owner, "witness2", owner)
    );
    await expectToBeReverted(
      "witness-exists",
      addWitness(users[0], "witness2", owner)
    );

    await expectToEqual(
      ethers.utils.formatBytes32String("witness2"),
      async () => {
        await addWitness(users[1], "witness2", owner);
        return await wallet.witnessNames(await users[1].getAddress());
      }
    );
    await expectToEqual(3, wallet.numberOfWitnesses);
  });

  it("Should NOT addWitness() before security period passed", async () => {
    const {
      wallet,
      users,
      transferOwnership,
      addWitness,
      removeWitness,
    } = await setupAuthorizable({
      numberOfWitnesses: 1,
    });
    const securityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("addWitness")
    );

    const newOwner = users[0];
    await transferOwnership(newOwner, [0]);
    await expectToBeReverted(
      "security-period-not-passed",
      addWitness(users[1], "witness2", newOwner)
    );

    await increaseTime(securityPeriod.time);
    await addWitness(users[1], "witness2", newOwner);
    await expectToBeReverted(
      "security-period-not-passed",
      addWitness(users[2], "witness3", newOwner)
    );

    await increaseTime(securityPeriod.time);
    await removeWitness(users[1], newOwner);
    await expectToBeReverted(
      "security-period-not-passed",
      addWitness(users[1], "witness2", newOwner)
    );

    await increaseTime(securityPeriod.time);
    await addWitness(users[1], "witness2", newOwner);
  });

  it("Should removeWitness()", async () => {
    const {wallet, owner, witnesses, removeWitness} = await setupAuthorizable({
      numberOfWitnesses: 3,
    });

    await expectToEqual(ethers.utils.formatBytes32String(""), async () => {
      await removeWitness(witnesses[0], owner);
      return await wallet.witnessNames(await witnesses[0].getAddress());
    });
    await expectToEqual(2, wallet.numberOfWitnesses);

    const securityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("removeWitness")
    );
    await increaseTime(securityPeriod.time);

    await expectToBeReverted("not-witness", removeWitness(owner, owner));
    await expectToEqual(ethers.utils.formatBytes32String(""), async () => {
      await removeWitness(witnesses[1], owner);
      return await wallet.witnessNames(await witnesses[1].getAddress());
    });
    await expectToEqual(1, wallet.numberOfWitnesses);

    await increaseTime(securityPeriod.time);
    await expectToBeReverted(
      "at-least-one-witness-required",
      removeWitness(witnesses[2], owner)
    );
  });

  it("Should NOT removeWitness() before security period passed", async () => {
    const {
      wallet,
      witnesses,
      users,
      transferOwnership,
      addWitness,
      removeWitness,
    } = await setupAuthorizable({
      numberOfWitnesses: 2,
    });
    const securityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("removeWitness")
    );

    const newOwner = users[0];
    await transferOwnership(newOwner, [0, 1]);
    await expectToBeReverted(
      "security-period-not-passed",
      removeWitness(witnesses[0], newOwner)
    );

    await increaseTime(securityPeriod.time);
    await addWitness(users[1], "witness2", newOwner);
    await expectToBeReverted(
      "security-period-not-passed",
      removeWitness(users[1], newOwner)
    );

    await increaseTime(securityPeriod.time);
    await removeWitness(users[1], newOwner);
    await expectToBeReverted(
      "security-period-not-passed",
      removeWitness(witnesses[0], newOwner)
    );

    await increaseTime(securityPeriod.time);
    await removeWitness(witnesses[0], newOwner);
  });
});
