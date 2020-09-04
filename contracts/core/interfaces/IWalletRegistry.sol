// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IWalletRegistry {
    function versionNames() external returns (bytes32[] memory);

    function register(bytes32 versionName, address addr) external;

    function latest() external view returns (bytes32 versionName, address addr);

    function queryWithAddress(address addr) external view returns (bytes32 versionName);

    function queryWithVersionName(bytes32 versionName) external view returns (address add);
}
