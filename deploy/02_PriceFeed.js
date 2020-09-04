const bre = require("@nomiclabs/buidler");
const create2 = require("../scripts/create2");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {deployer} = await getNamedAccounts();
  const network = bre.buidlerArguments.network;

  let makerPriceFeed;
  if (network === "buidlerevm") {
    const {address} = await create2({
      deployer,
      deployments,
      salt: "maker-price-feed-mock-0",
      contract: "MakerPriceFeedMock",
    });
    makerPriceFeed = address;
  } else if (network === "kovan") {
    makerPriceFeed = "0x9FfFE440258B79c5d6604001674A4722FfC0f7Bc";
  } else if (network === "rinkeby") {
    makerPriceFeed = "0xbfFf80B73F081Cc159534d922712551C5Ed8B3D3";
  } else if (network === "mainnet") {
    makerPriceFeed = "0x729D19f657BD0614b4985Cf1D82531c67569197B";
  } else {
    throw new Error("Unsupported network");
  }

  const contract = network === "buidlerevm" ? "PriceFeedMock" : "PriceFeed";
  await create2({
    deployer,
    deployments,
    contract,
    salt: "price-feed-0",
    initArgs: [makerPriceFeed],
    updateENS: ["price-feed-v0", "price-feed"],
  });
};
