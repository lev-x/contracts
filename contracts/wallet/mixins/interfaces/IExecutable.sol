// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../../libraries/Storage.sol";

interface IExecutable {
    event Executed(address indexed target, uint256 value, bytes data);

    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data,
        Storage.Signatures calldata signatures
    ) external payable returns (bytes[] memory);

    function executeHash(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external view returns (bytes32);
}
