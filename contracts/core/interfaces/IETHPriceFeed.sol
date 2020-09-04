// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IETHPriceFeed {
    function ethPriceInUSD() external view returns (uint256);
}
