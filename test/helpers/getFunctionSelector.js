module.exports = (contract, name) => {
  return contract.interface.getSighash(contract.interface.getFunction(name));
};
