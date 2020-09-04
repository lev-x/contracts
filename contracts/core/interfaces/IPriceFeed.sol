// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IPriceFeed {
    function ethPriceInUSD(uint256 amount) external view returns (uint256);

    function erc20PriceInETH(address token, uint256 amount) external view returns (uint256);

    function erc20PriceInUSD(address token, uint256 amount) external view returns (uint256);
}
