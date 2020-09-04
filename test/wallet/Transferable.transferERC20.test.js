const {ethers, deployments} = require("@nomiclabs/buidler");
const {utils, BigNumber} = ethers;
const {
  sign,
  setupWallet,
  getAddress,
  getContract,
  expectToBeReverted,
  expectToDeepEqual,
  expectToEqual,
  expectLastExecutedAt,
  increaseTime,
} = require("../helpers");

const setupTransferable = async (config) => {
  const {wallet, owner, witnesses, users} = await setupWallet(config);
  const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
  const erc20 = await ERC20Mock.deploy();

  const balanceOfERC20 = async (who) => {
    const address = await getAddress(who);
    return await erc20.balanceOf(address);
  };

  const mintERC20 = async (to, value) => {
    const address = await getAddress(to);
    return await erc20.mint(address, value);
  };

  const transferERC20 = async (
    to,
    value,
    {signer = null, witnessIndexesToSign = []} = {}
  ) => {
    const address = await getAddress(to);
    const message = await wallet.transferERC20Hash(
      erc20.address,
      address,
      value
    );
    const signatures = [];
    for (const i of witnessIndexesToSign) {
      signatures.push(await sign(witnesses[i], message));
    }
    const tx = await wallet.transferERC20(erc20.address, address, value, [
      await sign(signer || owner, message),
      signatures,
    ]);
    await expectLastExecutedAt(wallet, "transferERC20", tx.blockNumber);
    return tx;
  };

  return {
    wallet,
    owner,
    witnesses,
    users,
    erc20,
    balanceOfERC20,
    mintERC20,
    transferERC20,
  };
};

describe("Transferable.transferERC20", function () {
  const ZERO = BigNumber.from(0);
  const TOKENS_100 = utils.parseUnits("100", 8);

  beforeEach(async () => {
    await deployments.fixture();
  });

  it("Should transferERC20() with 0 witness", async () => {
    const {
      wallet,
      users,
      erc20,
      balanceOfERC20,
      mintERC20,
      transferERC20,
    } = await setupTransferable({
      numberOfWitnesses: 1,
    });
    const priceFeed = await getContract("PriceFeedMock");

    const TOKENS_100_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      TOKENS_100
    );
    const TOKENS_200_IN_USD = TOKENS_100_IN_USD.mul(BigNumber.from(2));

    await expectToEqual(
      await wallet.transferCapacityInUSD(0),
      wallet.minimumTransferLimitInUSD()
    );
    await expectToEqual(ZERO, wallet.cumulativeSpendingInUSD(0));

    await expectToBeReverted(
      "not-enough-balance",
      transferERC20(users[0], TOKENS_100)
    );

    await expectToEqual(TOKENS_100, async () => {
      await mintERC20(wallet, TOKENS_100);
      return await balanceOfERC20(wallet.address);
    });

    await expectToDeepEqual(
      {
        senderBalance: (await balanceOfERC20(wallet)).sub(TOKENS_100),
        receiverBalance: (await balanceOfERC20(users[0])).add(TOKENS_100),
        capacity: (await wallet.transferCapacityInUSD(0)).sub(
          TOKENS_100_IN_USD
        ),
        spending: TOKENS_100_IN_USD,
      },
      async () => {
        await transferERC20(users[0], TOKENS_100);
        return {
          senderBalance: await balanceOfERC20(wallet),
          receiverBalance: await balanceOfERC20(users[0]),
          capacity: await wallet.transferCapacityInUSD(0),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );

    await mintERC20(wallet, TOKENS_100);
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_100)
    );

    await increaseTime(await wallet.transferCapacityResetPeriod());

    await expectToDeepEqual(
      {
        capacity: (await wallet.transferCapacityInUSD(0)).sub(
          TOKENS_100_IN_USD
        ),
        spending: TOKENS_200_IN_USD,
      },
      async () => {
        await transferERC20(users[0], TOKENS_100);
        return {
          capacity: await wallet.transferCapacityInUSD(0),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );
    await mintERC20(wallet, TOKENS_100);
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_100)
    );
  });

  it("Should transferERC20() with 1 witness", async () => {
    const {
      wallet,
      users,
      erc20,
      mintERC20,
      transferERC20,
    } = await setupTransferable({
      numberOfWitnesses: 1,
    });
    const priceFeed = await getContract("PriceFeedMock");

    const TOKENS_900 = utils.parseUnits("900", 8);
    const TOKENS_100_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      TOKENS_100
    );
    const TOKENS_900_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      TOKENS_900
    );
    const TOKENS_1000_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      utils.parseUnits("1000", 8)
    );

    await expectToEqual(
      await wallet.transferCapacityInUSD(1),
      (await wallet.minimumTransferLimitInUSD()).mul(BigNumber.from(10))
    );
    await expectToEqual(
      await wallet.transferCapacityInUSD(1),
      (await wallet.transferCapacityInUSD(0)).mul(BigNumber.from(10))
    );

    await mintERC20(wallet, utils.parseUnits("1000", 8));
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_900, {
        witnessIndexesToSign: [],
      })
    );

    await expectToDeepEqual(
      {
        capacity: (await wallet.transferCapacityInUSD(1)).sub(
          TOKENS_900_IN_USD
        ),
        spending: TOKENS_900_IN_USD,
      },
      async () => {
        await transferERC20(users[0], TOKENS_900, {
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
        capacity: (await wallet.transferCapacityInUSD(1)).sub(
          TOKENS_100_IN_USD
        ),
        spending: TOKENS_1000_IN_USD,
      },
      async () => {
        await transferERC20(users[0], TOKENS_100, {
          witnessIndexesToSign: [0],
        });
        return {
          capacity: await wallet.transferCapacityInUSD(1),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );

    await mintERC20(wallet, TOKENS_100);
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_100, {
        witnessIndexesToSign: [0],
      })
    );
  });

  it("Should transferERC20() with 2 witness", async () => {
    const {
      wallet,
      users,
      erc20,
      mintERC20,
      transferERC20,
    } = await setupTransferable({
      numberOfWitnesses: 2,
    });
    const priceFeed = await getContract("PriceFeedMock");

    const TOKENS_9900 = utils.parseUnits("9900", 8);
    const TOKENS_100_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      TOKENS_100
    );
    const TOKENS_9900_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      TOKENS_9900
    );
    const TOKENS_10000_IN_USD = await priceFeed.erc20PriceInUSD(
      erc20.address,
      utils.parseUnits("10000", 8)
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

    await mintERC20(wallet, utils.parseUnits("10000", 8));
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_9900, {
        witnessIndexesToSign: [],
      })
    );
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_9900, {
        witnessIndexesToSign: [0],
      })
    );
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_9900, {
        witnessIndexesToSign: [1],
      })
    );

    await expectToDeepEqual(
      {
        capacity: (await wallet.transferCapacityInUSD(2)).sub(
          TOKENS_9900_IN_USD
        ),
        spending: TOKENS_9900_IN_USD,
      },
      async () => {
        await transferERC20(users[0], TOKENS_9900, {
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
        capacity: (await wallet.transferCapacityInUSD(2)).sub(
          TOKENS_100_IN_USD
        ),
        spending: TOKENS_10000_IN_USD,
      },
      async () => {
        await transferERC20(users[0], TOKENS_100, {
          witnessIndexesToSign: [0, 1],
        });
        return {
          capacity: await wallet.transferCapacityInUSD(2),
          spending: await wallet.cumulativeSpendingInUSD(0),
        };
      }
    );

    await mintERC20(wallet, TOKENS_100);
    await expectToBeReverted(
      "transfer-limit-exceeded",
      transferERC20(users[0], TOKENS_100, {
        witnessIndexesToSign: [0, 1],
      })
    );
  });

  it("Should not transferERC20() before security period passed", async () => {
    const {
      wallet,
      witnesses,
      users,
      mintERC20,
      transferERC20,
    } = await setupTransferable({
      numberOfWitnesses: 1,
    });

    await mintERC20(wallet, TOKENS_100);

    const newOwner = await users[0].getAddress();
    const message = await wallet.transferOwnershipHash(newOwner);
    const signature = await sign(witnesses[0], message);
    await wallet.transferOwnership(newOwner, ["0x", [signature]]);

    await expectToBeReverted(
      "security-period-not-passed",
      transferERC20(users[1], TOKENS_100)
    );

    const securityPeriod = await wallet.securityPeriod(
      wallet.interface.getSighash("transferERC20")
    );
    await increaseTime(securityPeriod.time);
    await transferERC20(users[1], TOKENS_100, {
      signer: users[0],
    });
  });
});
