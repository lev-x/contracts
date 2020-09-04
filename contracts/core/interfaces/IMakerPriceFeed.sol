// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IMakerPriceFeed {
    function read() external view returns (bytes32);
}
