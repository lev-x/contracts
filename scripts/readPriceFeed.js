const {ethers, deployments} = require("@nomiclabs/buidler");
const readline = require("readline-sync");
const {utils} = ethers;

async function main() {
  const token = readline.question("ERC20: ");
  const decimals = readline.question("Decimals: ");

  const ONE_ETH = utils.parseEther("1");
  const ONE_TOKEN = utils.parseUnits("1", decimals);

  const network = bre.buidlerArguments.network;
  const contract = network === "buidlerevm" ? "PriceFeedMock" : "PriceFeed";
  const {abi, address} = await deployments.get(contract);
  const priceFeed = await ethers.getContractAt(abi, address);
  const ethPrice = await priceFeed.ethPriceInUSD(ONE_ETH);
  const priceInETH = await priceFeed.erc20PriceInETH(token, ONE_TOKEN);
  const price = await priceFeed.erc20PriceInUSD(token, ONE_TOKEN);
  console.log(utils.formatEther(ethPrice) + " $/ETH");
  console.log(" * " + utils.formatEther(priceInETH) + " ETH");
  console.log(" = " + utils.formatEther(price) + " $");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
