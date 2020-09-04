usePlugin("@nomiclabs/buidler-ethers");
usePlugin("@nomiclabs/buidler-waffle");
usePlugin("buidler-spdx-license-identifier");
usePlugin("buidler-deploy");
// usePlugin("buidler-gas-reporter");

require("dotenv/config");

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();
  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

module.exports = {
  defaultNetwork: "buidlerevm",
  networks: {
    buidlerevm: {
      gas: 12000000,
      blockGasLimit: 12000000,
      allowUnlimitedContractSize: true,
    },
    kovan: {
      url:
        "https://eth-kovan.alchemyapi.io/v2/QWxHlrdaOHTlaIIbe_IabW0WuNhr2RhY",
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY,
        process.env.WITNESS_PRIVATE_KEY,
      ],
    },
    rinkeby: {
      url:
        "https://eth-rinkeby.alchemyapi.io/v2/7G8mS7xhYgFAXuQ4h_zVCn0zoxjgHARr",
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY,
        process.env.WITNESS_PRIVATE_KEY,
      ],
    },
    mainnet: {
      url:
        "https://eth-mainnet.alchemyapi.io/v2/XJnOcVECGudg6TXd78CsRXl-cFpuunzZ",
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY,
        process.env.WITNESS_PRIVATE_KEY,
      ],
    },
  },
  namedAccounts: {
    deployer: 0,
    witness: 1,
  },
  solc: {
    version: "0.6.8",
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
