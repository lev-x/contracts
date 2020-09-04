// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IENSGateway {
    event SubdomainRegistered(bytes32 indexed label, address owner, address addr);

    function ens() external view returns (address);

    function resolver() external view returns (address);

    function tld() external view returns (string memory);

    function tldNode() external view returns (bytes32);

    function subdomainNode(bytes32 label) external view returns (bytes32);

    function ownerOfSubdomain(bytes32 label) external view returns (address);

    function resolverOfSubdomain(bytes32 label) external view returns (address);

    function registerSubdomain(bytes32 label, address addr) external;
}
