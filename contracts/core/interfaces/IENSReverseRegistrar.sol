// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IENSReverseRegistrar {
    function ens() external view returns (address);

    function defaultResolver() external view returns (address);

    function claim(address owner) external returns (bytes32);

    function claimWithResolver(address owner, address resolver) external returns (bytes32);

    function setName(string calldata name) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}
