const {deployments} = require("@nomiclabs/buidler");
const {
  sign,
  setupWallet,
  increaseTime,
  expectToBeReverted,
  expectToEqual,
  expectLastExecutedAt,
} = require("../helpers");

const setupLockable = async (config) => {
  const {wallet, witnesses} = await setupWallet(config);

  const lock = async (witnessIndexesToSign = []) => {
    const message = await wallet.lockHash();
    const signatures = [];
    for (const i of witnessIndexesToSign) {
      signatures.push(await sign(witnesses[i], message));
    }
    const tx = await wallet.lock(["0x", signatures]);
    await expectLastExecutedAt(wallet, "lock", tx.blockNumber);
    return tx;
  };

  const unlock = async (witnessIndexesToSign = []) => {
    const message = await wallet.unlockHash();
    const signatures = [];
    for (const i of witnessIndexesToSign) {
      signatures.push(await sign(witnesses[i], message));
    }
    const tx = await wallet.unlock(["0x", signatures]);
    await expectLastExecutedAt(wallet, "unlock", tx.blockNumber);
    return tx;
  };

  return {wallet, witnesses, lock, unlock};
};

describe("Lockable", function () {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should lock()", async () => {
    const {wallet, lock, unlock} = await setupLockable({
      numberOfWitnesses: 3,
    });
    const expectLocked = async (witnessIndexesToSign) => {
      await expectToBeReverted("already-locked", lock(witnessIndexesToSign));
      const unlockSecurityPeriod = await wallet.securityPeriod(
        wallet.interface.getSighash("unlock")
      );
      await increaseTime(unlockSecurityPeriod.time);
      await unlock([0, 1, 2]);

      await lock(witnessIndexesToSign);
      await expectToEqual(true, wallet.locked);
    };

    await expectToEqual(false, wallet.locked);

    await expectToBeReverted("more-signatures-required", lock([]));
    await expectToEqual(true, async () => {
      await lock([0]);
      return await wallet.locked();
    });

    await expectLocked([0]);
    await expectLocked([1]);
    await expectLocked([2]);
    await expectLocked([0, 1]);
    await expectLocked([0, 2]);
    await expectLocked([0, 1]);
    await expectLocked([0, 1, 2]);
  });

  it("Should unlock() with 1 witness", async () => {
    const {wallet, lock, unlock} = await setupLockable({
      numberOfWitnesses: 1,
    });

    await expectToEqual(false, wallet.locked);
    await expectToBeReverted("not-locked", unlock([0]));

    await lock([0]);
    await expectToBeReverted("security-period-not-passed", unlock([0]));

    const unlockSecurityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("unlock")
    );
    await increaseTime(unlockSecurityPeriod.time);

    await expectToBeReverted("more-signatures-required", unlock([]));
    await expectToEqual(false, async () => {
      await unlock([0]);
      return await wallet.locked();
    });
  });

  it("Should unlock() with 2 witnesses", async () => {
    const {wallet, lock, unlock} = await setupLockable({
      numberOfWitnesses: 2,
    });

    await lock([0]);

    const unlockSecurityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("unlock")
    );
    await increaseTime(unlockSecurityPeriod.time);

    await expectToBeReverted("more-signatures-required", unlock([]));
    await expectToBeReverted("more-signatures-required", unlock([0]));
    await expectToBeReverted("more-signatures-required", unlock([1]));

    await unlock([0, 1]);
    await expectToEqual(false, wallet.locked);
  });

  it("Should unlock() with 3 witnesses", async () => {
    const {wallet, lock, unlock} = await setupLockable({
      numberOfWitnesses: 3,
    });
    const expectUnlockedAfterSecurityPeriod = async (witnessIndexesToSign) => {
      const unlockSecurityPeriod = await wallet.securityPeriod(
        wallet.interface.getSighash("unlock")
      );
      await increaseTime(unlockSecurityPeriod.time);

      await unlock(witnessIndexesToSign);
      await expectToEqual(false, wallet.locked);
    };
    const expectToBeRevertedAfterSecurityPeriod = async (
      reason,
      witnessIndexesToSign
    ) => {
      const unlockSecurityPeriod = await wallet.securityPeriod(
        wallet.interface.getSighash("unlock")
      );
      await increaseTime(unlockSecurityPeriod.time);
      await expectToBeReverted(reason, unlock(witnessIndexesToSign));
    };

    await lock([0]);
    const unlockSecurityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("unlock")
    );
    await increaseTime(unlockSecurityPeriod.time);

    await expectToBeRevertedAfterSecurityPeriod("more-signatures-required", []);
    await expectToBeRevertedAfterSecurityPeriod("more-signatures-required", [
      0,
    ]);
    await expectToBeRevertedAfterSecurityPeriod("more-signatures-required", [
      1,
    ]);
    await expectToBeRevertedAfterSecurityPeriod("more-signatures-required", [
      2,
    ]);

    await unlock([0, 1, 2]);
    await expectToEqual(false, wallet.locked);

    await lock([0]);
    await expectUnlockedAfterSecurityPeriod([0, 1]);
    await lock([0]);
    await expectUnlockedAfterSecurityPeriod([0, 2]);
    await lock([0]);
    await expectUnlockedAfterSecurityPeriod([1, 2]);
    await lock([0]);
    await expectUnlockedAfterSecurityPeriod([0, 1, 2]);
  });
});
