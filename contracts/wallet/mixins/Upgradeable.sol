// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./BaseMixin.sol";
import "./interfaces/IUpgradeable.sol";
import "../../core/interfaces/IWalletRegistry.sol";

/**
 * @notice Implements https://eips.ethereum.org/EIPS/eip-1822
 * EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
 */
abstract contract Upgradeable is BaseMixin, IUpgradeable {
    // keccak256("PROXIABLE") = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
    bytes32
        private constant UUID = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    function _initialize() internal virtual {
        _storage.setSigningRequirements(this.upgrade.selector, true, 0);
        _storage.setSecurityPeriod(this.upgrade.selector, 0, new bytes4[](0));
    }

    function proxiableUUID() public override pure returns (bytes32) {
        return UUID;
    }

    function implementation() public override view returns (address addr) {
        assembly {
            addr := sload(UUID)
        }
    }

    /**
     * @notice Upgrades to a new implementation
     *
     * Signature of the owner required
     */
    function upgrade(address impl, Storage.Signatures memory signatures)
        public
        override
        whenInitialized
    {
        _ensureSignaturesValid(this.upgrade.selector, upgradeHash(impl), signatures);

        IWalletRegistry registry = IWalletRegistry(
            resolveENS(keccak256(abi.encodePacked("wallet-registry-v0")))
        );
        require(registry.queryWithAddress(impl) != bytes32(0), "not-registered");
        require(UUID == Upgradeable(impl).proxiableUUID(), "not-upgradeable");

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.upgrade.selector);

        assembly {
            sstore(UUID, impl)
        }

        emit Upgraded(impl);
    }

    /**
     * @return a hash used to generate signature to properly call 'upgrade()'
     */
    function upgradeHash(address impl) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.upgrade.selector,
                    impl
                )
            );
    }
}
