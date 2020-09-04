const {expect} = require("./chai");
const getFunctionSelector = require("./getFunctionSelector");

module.exports = async (contract, methodName, blockNumber) => {
  const block = await ethers.provider.getBlock(blockNumber);
  const lastLockedTime = await contract.lastExecutionTime(
    getFunctionSelector(contract, methodName)
  );
  expect(lastLockedTime).to.equal(block.timestamp);
};
