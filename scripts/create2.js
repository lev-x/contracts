const {run, ethers} = require("@nomiclabs/buidler");
const {replaceInFile} = require("replace-in-file");
const approveENSGateway = require("./approveENSGateway");
const registerOrUpdateENS = require("./registerOrUpdateENS");
const {utils} = ethers;

const replaceAddressInFiles = async (name, address) => {
  address = await utils.getAddress(address);
  const result = await replaceInFile({
    files: "./contracts/**/*.sol",
    from: new RegExp(name + " = 0x([0-9a-fA-F]{40})"),
    to: name + " = " + address,
  });
  return result.filter((file) => file.hasChanged);
};

module.exports = async ({
  deployer,
  deployments,
  contract,
  args,
  libraries,
  salt,
  initArgs,
  replacement,
  updateENS,
}) => {
  const {create2, read, execute} = deployments;

  const {deploy} = await create2(contract, {
    from: deployer,
    args: args || [],
    libraries: libraries || {},
    salt: utils.id(salt),
    log: true,
    skipIfAlreadyDeployed: true,
  });
  const deployResult = await deploy();
  if (initArgs && initArgs.length > 0) {
    const initialized = await read(contract, {from: deployer}, "initialized");
    if (!initialized) {
      await execute(
        contract,
        {
          from: deployer,
          log: true,
        },
        "initialize",
        ...initArgs
      );
    }
  }
  if (deployResult.newlyDeployed) {
    if (updateENS) {
      await approveENSGateway();

      if (!Array.isArray(updateENS)) {
        updateENS = [updateENS];
      }
      for (const subdomain of updateENS) {
        await registerOrUpdateENS(subdomain, deployResult.address);
      }
    }
  }
  if (replacement) {
    const result = await replaceAddressInFiles(
      replacement,
      deployResult.address
    );
    if (result.length > 0) {
      result.forEach((file) =>
        console.log("replaced " + replacement + " in " + file.file)
      );
      await run("compile");
    }
  }
  console.log("");
  return deployResult;
};
