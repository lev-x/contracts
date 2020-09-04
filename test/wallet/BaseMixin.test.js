const {ethers, deployments} = require("@nomiclabs/buidler");
const {expectToEqual, setupWallet} = require("../helpers");

const keccak256 = (message) => {
  return ethers.utils.arrayify(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message))
  );
};

describe("BaseMixin", function () {
  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should verify signature and return magic value", async function () {
    const {wallet, owner, witnesses} = await setupWallet({
      numberOfWitnesses: 1,
    });

    const hash = keccak256("Message to be signed");
    const signature = await owner.signMessage(hash);
    await expectToEqual("0x1626ba7e", wallet.isValidSignature(hash, signature));

    const wrongSignature = await witnesses[0].signMessage(hash);
    await expectToEqual(
      "0xffffffff",
      wallet.isValidSignature(hash, wrongSignature)
    );
  });

  it("Should verify owner signature", async function () {
    const {wallet, owner, witnesses} = await setupWallet({
      numberOfWitnesses: 1,
    });

    const hash = keccak256("Message to be signed");
    const signature = await owner.signMessage(hash);
    await expectToEqual(true, wallet.isValidOwnerSignature(hash, signature));

    const wrongSignature = await witnesses[0].signMessage(hash);
    await expectToEqual(
      false,
      wallet.isValidOwnerSignature(hash, wrongSignature)
    );
  });

  it("Should verify witness signatures", async function () {
    const {wallet, owner, witnesses} = await setupWallet({
      numberOfWitnesses: 3,
    });

    const hash = keccak256("Message to be signed");
    const signatures = [];
    for (const witness of witnesses) {
      const signature = await witness.signMessage(hash);
      signatures.push(signature);
    }
    await expectToEqual(
      true,
      wallet.areValidWitnessSignatures(hash, signatures)
    );

    const wrongSignatures = [await owner.signMessage(hash)];
    await expectToEqual(
      false,
      wallet.areValidWitnessSignatures(hash, wrongSignatures)
    );

    const duplicateSignatures = [
      await witnesses[0].signMessage(hash),
      await witnesses[0].signMessage(hash),
      await witnesses[1].signMessage(hash),
    ];
    await expectToEqual(
      false,
      wallet.areValidWitnessSignatures(hash, duplicateSignatures)
    );
  });
});
