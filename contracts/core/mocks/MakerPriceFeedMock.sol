// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "../interfaces/IMakerPriceFeed.sol";

contract MakerPriceFeedMock is IMakerPriceFeed {
    function read() public override view returns (bytes32) {
        return bytes32(uint256(10**20)); // 100 USD
    }
}
