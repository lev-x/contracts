// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface ITXRelayer {
    event Relayed(address indexed target, bytes data);
    event FeeCollected(address feeToken, uint256 amount);

    function freeExecutionResetPeriod() external pure returns (uint256);

    function freeExecutionMax() external pure returns (uint256);

    function freeExecutionLeft(address addr) external view returns (uint256);

    function relay(
        address target,
        uint256 value,
        bytes calldata data,
        address feeToken
    ) external payable returns (bytes memory);
}
