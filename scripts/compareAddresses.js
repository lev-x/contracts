const {ethers} = require("@nomiclabs/buidler");

module.exports = async (a1, a2) => {
  return (
    (await ethers.utils.getAddress(a1)) === (await ethers.utils.getAddress(a2))
  );
};
