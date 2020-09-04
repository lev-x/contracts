// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../mixins/interfaces/IBaseMixin.sol";
import "../mixins/interfaces/IAuthorizable.sol";
import "../mixins/interfaces/IUpgradeable.sol";
import "../mixins/interfaces/ILockable.sol";
import "../mixins/interfaces/ITransferable.sol";
import "../mixins/interfaces/IExecutable.sol";
import "../../core/interfaces/IENSGateway.sol";

interface IWallet is
    IBaseMixin,
    IAuthorizable,
    IUpgradeable,
    ILockable,
    ITransferable,
    IExecutable
{
    function initialize(
        IENSGateway ensGateway,
        bytes32 label,
        address owner,
        address[] calldata witnessAddrs,
        bytes32[] calldata witnessNames
    ) external;
}
