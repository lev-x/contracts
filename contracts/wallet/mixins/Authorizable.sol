// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./BaseMixin.sol";
import "./interfaces/IAuthorizable.sol";

/**
 * @notice Implements https://eips.ethereum.org/EIPS/eip-173
 * EIP-173: Contract Ownership Standard
 */
abstract contract Authorizable is BaseMixin, IAuthorizable {
    function _initialize() internal virtual {
        _storage.setSigningRequirements(
            this.transferOwnership.selector,
            false,
            ((_storage.numberOfWitnesses() + 1) * 2) / 3
        );
        _storage.setSigningRequirements(this.addWitness.selector, true, 0);
        _storage.setSigningRequirements(this.removeWitness.selector, true, 0);

        _storage.setSecurityPeriod(this.transferOwnership.selector, 0, new bytes4[](0));
        bytes4[] memory dependencies = new bytes4[](3);
        dependencies[0] = this.transferOwnership.selector;
        dependencies[1] = this.addWitness.selector;
        dependencies[2] = this.removeWitness.selector;
        _storage.setSecurityPeriod(this.addWitness.selector, 24 hours, dependencies);
        _storage.setSecurityPeriod(this.removeWitness.selector, 24 hours, dependencies);
    }

    function owner() public override view returns (address) {
        return _storage.owner();
    }

    function witnessNames(address addr) public override view returns (bytes32) {
        return _storage.witnessNames(addr);
    }

    function witnesses(uint256 index) public override view returns (address) {
        return _storage.witnesses(index);
    }

    function numberOfWitnesses() public override view returns (uint256) {
        return _storage.numberOfWitnesses();
    }

    /**
     * @notice Transfers the ownership to a new owner
     *
     * Signatures of '((n + 1) * 2) / 3' required where 'n' is the number of the witnesses
     */
    function transferOwnership(address newOwner, Storage.Signatures memory signatures)
        public
        override
        whenInitialized
    {
        _ensureSecurityPeriodPassed(this.transferOwnership.selector);
        _ensureSignaturesValid(
            this.transferOwnership.selector,
            transferOwnershipHash(newOwner),
            signatures
        );

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.transferOwnership.selector);

        address previousOwner = _storage.owner();
        _storage.transferOwnership(newOwner);

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @return a hash used to generate signature to properly call 'transferOwnership()'
     */
    function transferOwnershipHash(address newOwner) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.transferOwnership.selector,
                    newOwner
                )
            );
    }

    /**
     * @notice Adds a new owner
     *
     * Signatures of the owner needed
     */
    function addWitness(
        address addr,
        bytes32 name,
        Storage.Signatures memory signatures
    ) public override whenInitialized whenNotLocked {
        _ensureSecurityPeriodPassed(this.addWitness.selector);
        _ensureSignaturesValid(this.addWitness.selector, addWitnessHash(addr, name), signatures);

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.addWitness.selector);
        _storage.addWitness(addr, name);

        emit WitnessAdded(addr, name);
    }

    /**
     * @return a hash used to generate signature to properly call 'addWitness()'
     */
    function addWitnessHash(address addr, bytes32 name) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.addWitness.selector,
                    addr,
                    name
                )
            );
    }

    /**
     * @notice Removes an existing owner
     *
     * Signature of the owner needed
     */
    function removeWitness(address addr, Storage.Signatures memory signatures)
        public
        override
        whenInitialized
        whenNotLocked
    {
        _ensureSecurityPeriodPassed(this.removeWitness.selector);
        _ensureSignaturesValid(this.removeWitness.selector, removeWitnessHash(addr), signatures);

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.removeWitness.selector);
        _storage.removeWitness(addr);

        emit WitnessRemoved(addr);
    }

    /**
     * @return a hash used to generate signature to properly call 'removeWitness()'
     */
    function removeWitnessHash(address addr) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.removeWitness.selector,
                    addr
                )
            );
    }
}
