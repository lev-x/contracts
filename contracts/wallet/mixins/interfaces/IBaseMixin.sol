// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../../libraries/Storage.sol";

interface IBaseMixin {
    event Initialized();
    event Spent(uint256 valueInUSD, uint256 timestamp);

    function initialized() external view returns (bool);

    function label() external view returns (bytes32);

    function nonce() external view returns (uint256);

    function signingRequirements(bytes4 methodId)
        external
        view
        returns (Storage.SigningRequirements memory);

    function securityPeriod(bytes4 methodId) external view returns (Storage.SecurityPeriod memory);

    function lastExecutionTime(bytes4 selector) external view returns (uint256);

    function resolveENS(bytes32 subdomain) external view returns (address);

    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bytes4);

    function isValidOwnerSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool);

    function areValidWitnessSignatures(bytes32 hash, bytes[] calldata signatures)
        external
        view
        returns (bool);
}
