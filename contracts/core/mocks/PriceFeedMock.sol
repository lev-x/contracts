// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IPriceFeed.sol";

contract PriceFeedMock is IPriceFeed {
    using SafeMath for uint256;

    // solhint-disable-next-line no-empty-blocks
    function initialize(address) public {}

    function ethPriceInUSD(uint256 amount) public override view returns (uint256) {
        return amount.mul(100 * 10**18).div(10**18); // 100$ per 1ETH
    }

    function erc20PriceInETH(address token, uint256 amount) public override view returns (uint256) {
        uint256 decimals = ERC20(token).decimals();
        return amount.mul(10**16).div(10**decimals); // 0.01ETH per 1ERC20
    }

    function erc20PriceInUSD(address token, uint256 amount) public override view returns (uint256) {
        uint256 decimals = ERC20(token).decimals();
        return amount.mul(10**18).div(10**decimals); // 1$ per 1ERC20
    }
}
