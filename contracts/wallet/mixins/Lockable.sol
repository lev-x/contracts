// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./BaseMixin.sol";
import "./interfaces/ILockable.sol";

abstract contract Lockable is BaseMixin, ILockable {
    function _initialize() internal virtual {
        _storage.setSigningRequirements(this.lock.selector, false, 1);
        _storage.setSigningRequirements(
            this.unlock.selector,
            false,
            ((_storage.numberOfWitnesses() + 1) * 2) / 3
        );

        _storage.setSecurityPeriod(this.lock.selector, 0, new bytes4[](0));
        bytes4[] memory dependencies = new bytes4[](1);
        dependencies[0] = this.lock.selector;
        _storage.setSecurityPeriod(this.unlock.selector, 24 hours, dependencies);
    }

    function locked() public override view returns (bool) {
        return _storage.locked();
    }

    /**
     * @notice Locks the wallet
     *
     * Signature of at least one of the witnesses required
     */
    function lock(Storage.Signatures memory signatures)
        public
        override
        whenInitialized
        whenNotLocked
    {
        _ensureSignaturesValid(this.lock.selector, lockHash(), signatures);

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.lock.selector);
        _storage.setLocked(true);

        emit Locked();
    }

    /**
     * @return a hash used to generate signature to properly call 'lock()'
     */
    function lockHash() public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.lock.selector
                )
            );
    }

    /**
     * @notice Unlocks the wallet
     *
     * Signatures of '((n + 1) * 2) / 3' required where 'n' is the number of the witnesses
     * Also, 24 hours needs to have passed after the lock has been called
     */
    function unlock(Storage.Signatures memory signatures)
        public
        override
        whenInitialized
        whenLocked
    {
        _ensureSecurityPeriodPassed(this.unlock.selector);
        _ensureSignaturesValid(this.unlock.selector, unlockHash(), signatures);

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.unlock.selector);
        _storage.setLocked(false);

        emit Unlocked();
    }

    /**
     * @return a hash used to generate signature to properly call 'unlock()'
     */
    function unlockHash() public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.unlock.selector
                )
            );
    }
}
