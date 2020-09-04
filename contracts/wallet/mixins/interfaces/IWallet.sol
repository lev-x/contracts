// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IAuthorizable.sol";
import "./IUpgradeable.sol";
import "./ILockable.sol";
import "./ITransferable.sol";
import "./IExecutable.sol";

interface IWallet is IAuthorizable, IUpgradeable, ILockable, ITransferable, IExecutable {
    function initialize(
        address owner,
        address[] calldata witnessAddrs,
        bytes32[] calldata witnessNames
    ) external;
}
