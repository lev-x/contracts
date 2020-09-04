// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../../libraries/Storage.sol";

interface IAuthorizable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WitnessAdded(address indexed addr, bytes32 name);
    event WitnessRemoved(address indexed addr);

    function owner() external view returns (address);

    function witnessNames(address addr) external view returns (bytes32);

    function witnesses(uint256 index) external view returns (address);

    function numberOfWitnesses() external view returns (uint256);

    function transferOwnership(address newOwner, Storage.Signatures calldata signatures) external;

    function transferOwnershipHash(address newOwner) external view returns (bytes32);

    function addWitness(
        address ownerAddr,
        bytes32 ownerName,
        Storage.Signatures calldata signatures
    ) external;

    function addWitnessHash(address ownerAddr, bytes32 ownerName) external view returns (bytes32);

    function removeWitness(address ownerAddr, Storage.Signatures calldata signatures) external;

    function removeWitnessHash(address ownerAddr) external view returns (bytes32);
}
