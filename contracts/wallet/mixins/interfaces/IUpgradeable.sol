// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../../libraries/Storage.sol";

interface IUpgradeable {
    event Upgraded(address implementation);

    function proxiableUUID() external pure returns (bytes32);

    function implementation() external view returns (address addr);

    function upgrade(address impl, Storage.Signatures calldata) external;

    function upgradeHash(address impl) external view returns (bytes32);
}
