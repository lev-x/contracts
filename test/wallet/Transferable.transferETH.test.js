const {ethers, deployments} = require("@nomiclabs/buidler");
const {utils, BigNumber} = ethers;
const {
  sign,
  setupWallet,
  getAddress,
  getBalance,
  getContract,
  expectToBeReverted,
  expectToDeepEqual,
  expectToEqual,
  expectLastExecutedAt,
  increaseTime,
} = require("../helpers");

const setupTransferable = async (config) => {
  const {wallet, owner, witnesses, users} = await setupWallet(config);

  const transferETH = async (
    to,
    value,
    {signer = null, witnessIndexesToSign = []} = {}
  ) => {
    const address = await getAddress(to);
    const message = await wallet.transferETHHash(address, value);
    const signatures = [];
    for (const i of witnessIndexesToSign) {
      signatures.push(await sign(witnesses[i], message));
    }
    const tx = await wallet.transferETH(address, value, [
      await sign(signer || owner, message),
      signatures,
    ]);
    await expectLastExecutedAt(wallet, "transferETH", tx.blockNumber);
    return tx;
  };

  return {wallet, owner, witnesses, users, transferETH};
};

describe("Transferable.transferETH", function () {
  const ZERO = BigNumber.from(0);
  const ONE_ETH = utils.parseEther("1");

  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should transferETH() with 0 witness", async () => {
    const {wallet, owner, users, transferETH} = await setupTransferable({
      numberOfWitnesses: 1,
    });
    const priceFeed = await getContract("PriceFeedMock");

    const ONE_ETH_IN_USD = await priceFeed.ethPriceInUSD(ONE_ETH);
    const TWO_ETH_IN_USD = ONE_ETH_IN_USD.mul(BigNumber.from(2));

    await expectToEqual(
      await wallet.transferCapacityInUSD(0),
      wallet.minimumTransferLimitInUSD()
    );
    await expectToEqual(ZERO, wallet.cumulativeSpendingInUSD(0));

    await expectToBeReverted(
      "not-enough-balance",
      transferETH(users[0], ONE_ETH)
    );

    await expectToEqual(ONE_ETH, async () => {
      await owner.sendTransaction({
        to: wallet.address,
        value: ONE_ETH,
      });
      return await ethers.provider.getBalance(wallet.address);
    });

    await expectToDeepEqual(
      {
        senderBalance: (await getBalance(wallet)).sub(ONE_ETH),
        receiverBalance: (await getBalance(users[0])).add(ONE_ETH),
        capacity: ZERO,
        spending: ONE_ETH_IN_USD,
      },
      async () => {
        await transferETH(users[0], ONE_ETH);
        return {
          senderBalance: await getBalance(wallet),
          receiverBalance: await getBalance(users[0]),
          capacity: await wallet.transferCapacityInUSD(0),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );

    await owner.sendTransaction({
      to: wallet.address,
      value: ONE_ETH,
    });
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferETH(users[0], ONE_ETH)
    );

    await increaseTime(await wallet.transferCapacityResetPeriod());

    await expectToDeepEqual(
      {
        capacity: ZERO,
        spending: TWO_ETH_IN_USD,
      },
      async () => {
        await transferETH(users[0], ONE_ETH);
        return {
          capacity: await wallet.transferCapacityInUSD(0),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );
  });

  it("Should transferETH() with 1 witness", async () => {
    const {wallet, owner, users, transferETH} = await setupTransferable({
      numberOfWitnesses: 1,
    });
    const priceFeed = await getContract("PriceFeedMock");

    const NINE_ETH = utils.parseEther("9");
    const ONE_ETH_IN_USD = await priceFeed.ethPriceInUSD(ONE_ETH);
    const NINE_ETH_IN_USD = await priceFeed.ethPriceInUSD(NINE_ETH);
    const TEN_ETH_IN_USD = await priceFeed.ethPriceInUSD(
      utils.parseEther("10")
    );

    await expectToEqual(
      await wallet.transferCapacityInUSD(1),
      (await wallet.minimumTransferLimitInUSD()).mul(BigNumber.from(10))
    );
    await expectToEqual(
      await wallet.transferCapacityInUSD(1),
      (await wallet.transferCapacityInUSD(0)).mul(BigNumber.from(10))
    );

    await owner.sendTransaction({
      to: wallet.address,
      value: utils.parseEther("10"),
    });

    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferETH(users[0], NINE_ETH, {
        witnessIndexesToSign: [],
      })
    );

    await expectToDeepEqual(
      {
        capacity: ONE_ETH_IN_USD,
        spending: NINE_ETH_IN_USD,
      },
      async () => {
        await transferETH(users[0], NINE_ETH, {
          witnessIndexesToSign: [0],
        });
        return {
          capacity: await wallet.transferCapacityInUSD(1),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );

    await expectToDeepEqual(
      {
        capacity: ZERO,
        spending: TEN_ETH_IN_USD,
      },
      async () => {
        await transferETH(users[0], ONE_ETH, {
          witnessIndexesToSign: [0],
        });
        return {
          capacity: await wallet.transferCapacityInUSD(1),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );
  });

  it("Should transferETH() with 2 witness", async () => {
    const {wallet, owner, users, transferETH} = await setupTransferable({
      numberOfWitnesses: 2,
    });
    const priceFeed = await getContract("PriceFeedMock");

    const NINETY_NINE_ETH = utils.parseEther("99");
    const ONE_ETH_IN_USD = await priceFeed.ethPriceInUSD(ONE_ETH);
    const NINETY_NINE_ETH_IN_USD = await priceFeed.ethPriceInUSD(
      NINETY_NINE_ETH
    );
    const HUNDRED_ETH_IN_USD = await priceFeed.ethPriceInUSD(
      utils.parseEther("100")
    );

    await expectToEqual(
      await wallet.transferCapacityInUSD(2),
      (await wallet.minimumTransferLimitInUSD()).mul(BigNumber.from(100))
    );
    await expectToEqual(
      await wallet.transferCapacityInUSD(2),
      (await wallet.transferCapacityInUSD(1)).mul(BigNumber.from(10))
    );
    await expectToEqual(
      await wallet.transferCapacityInUSD(2),
      (await wallet.transferCapacityInUSD(0)).mul(BigNumber.from(100))
    );

    await owner.sendTransaction({
      to: wallet.address,
      value: utils.parseEther("100"),
    });

    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferETH(users[0], NINETY_NINE_ETH, {
        witnessIndexesToSign: [],
      })
    );
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferETH(users[0], NINETY_NINE_ETH, {
        witnessIndexesToSign: [0],
      })
    );
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferETH(users[0], NINETY_NINE_ETH, {
        witnessIndexesToSign: [1],
      })
    );

    await expectToDeepEqual(
      {
        capacity: ONE_ETH_IN_USD,
        spending: NINETY_NINE_ETH_IN_USD,
      },
      async () => {
        await transferETH(users[0], NINETY_NINE_ETH, {
          witnessIndexesToSign: [0, 1],
        });
        return {
          capacity: await wallet.transferCapacityInUSD(2),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );

    await expectToDeepEqual(
      {
        capacity: ZERO,
        spending: HUNDRED_ETH_IN_USD,
      },
      async () => {
        await transferETH(users[0], ONE_ETH, {
          witnessIndexesToSign: [0, 1],
        });
        return {
          capacity: await wallet.transferCapacityInUSD(2),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );
  });

  it("Should not transferETH() before security period passed", async () => {
    const {
      wallet,
      owner,
      witnesses,
      users,
      transferETH,
    } = await setupTransferable({
      numberOfWitnesses: 1,
    });

    await owner.sendTransaction({
      to: wallet.address,
      value: ONE_ETH,
    });

    const newOwner = await users[0].getAddress();
    const message = await wallet.transferOwnershipHash(newOwner);
    const signature = await sign(witnesses[0], message);
    await wallet.transferOwnership(newOwner, ["0x", [signature]]);

    await expectToBeReverted(
      "security-period-not-passed",
      transferETH(users[1], ONE_ETH)
    );

    const securityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("transferETH")
    );
    await increaseTime(securityPeriod.time);
    await transferETH(users[1], ONE_ETH, {
      signer: users[0],
    });
  });
});
