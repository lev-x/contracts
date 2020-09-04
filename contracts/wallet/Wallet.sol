// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./mixins/BaseMixin.sol";
import "./mixins/Authorizable.sol";
import "./mixins/Upgradeable.sol";
import "./mixins/Lockable.sol";
import "./mixins/Transferable.sol";
import "./mixins/Executable.sol";
import "./interfaces/IWallet.sol";
import "../core/interfaces/IENSGateway.sol";

contract Wallet is
    BaseMixin,
    Authorizable,
    Upgradeable,
    Lockable,
    Transferable,
    Executable,
    IWallet
{
    /**
     * @notice Initializes the wallet
     */
    function initialize(
        IENSGateway ensGateway,
        bytes32 label,
        address owner,
        address[] memory witnessAddrs,
        bytes32[] memory witnessNames
    ) public override initializer {
        _initialize(ensGateway, label);
        require(witnessAddrs.length == witnessNames.length, "different-param-lengths");
        require(witnessAddrs.length > 0, "at-least-one-witness-required");

        _storage.transferOwnership(owner);
        for (uint256 i = 0; i < witnessAddrs.length; i++) {
            _storage.addWitness(witnessAddrs[i], witnessNames[i]);
        }

        _initialize();
    }

    function _initialize()
        internal
        override(Authorizable, Upgradeable, Lockable, Transferable, Executable)
    {
        Authorizable._initialize();
        Upgradeable._initialize();
        Lockable._initialize();
        Transferable._initialize();
        Executable._initialize();
    }
}
