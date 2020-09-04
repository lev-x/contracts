// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@ensdomains/resolver/contracts/Resolver.sol";

import "./interfaces/IBaseMixin.sol";
import "../../core/interfaces/IENSGateway.sol";
import "../../core/interfaces/IPriceFeed.sol";

/**
 * @notice Implements https://eips.ethereum.org/EIPS/eip-1271
 * EIP-1271: Standard Signature Validation Method for Contracts
 */
abstract contract BaseMixin is IBaseMixin {
    using Storage for Storage.Data;

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    bool private _initialized;
    bool private _initializing;
    uint256 private _status;
    IENSGateway private _ensGateway;
    Storage.Data internal _storage;

    modifier whenInitialized {
        require(_initialized, "not-initialized");
        _;
    }

    modifier initializer() {
        require(_initializing || !_initialized, "already-initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }

        emit Initialized();
    }

    modifier nonReentrant {
        require(_status != ENTERED, "reentrant-call");

        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }

    modifier whenLocked {
        require(_storage.locked(), "not-locked");
        _;
    }

    modifier whenNotLocked {
        require(!_storage.locked(), "already-locked");
        _;
    }

    function _initialize(IENSGateway ensGateway, bytes32 label) internal {
        require(address(ensGateway) != address(0), "invalid-ens-gateway");
        require(label != bytes32(0), "invalid-label");

        _status = NOT_ENTERED;
        _ensGateway = ensGateway;
        _ensGateway.registerSubdomain(label, address(this));
        _storage.setLabel(label);
    }

    function _ensureSignaturesValid(
        bytes4 methodId,
        bytes32 hash,
        Storage.Signatures memory signatures
    ) internal view {
        Storage.SigningRequirements storage requirements = _storage.signingRequirements(methodId);
        if (requirements.owner) {
            require(_storage.isValidOwnerSignature(hash, signatures.owner), "not-signed-by-owner");
        }
        require(signatures.witnesses.length >= requirements.witnesses, "more-signatures-required");
        require(
            _storage.areValidWitnessSignatures(hash, signatures.witnesses),
            "not-signed-by-witnesses"
        );
    }

    function _ensureSecurityPeriodPassed(bytes4 methodId) internal view {
        Storage.SecurityPeriod storage period = _storage.securityPeriod(methodId);
        for (uint256 i = 0; i < period.dependencies.length; i++) {
            require(
                now > _storage.lastExecutionTime(period.dependencies[i]) + period.time,
                "security-period-not-passed"
            );
        }
    }

    function _addETHSpending(uint256 value, uint256 numberOfWitnessSignatures) internal {
        uint256 valueInUSD = _priceFeed().ethPriceInUSD(value);
        uint256 limitInUSD = _storage.transferCapacityInUSD(numberOfWitnessSignatures);
        require(valueInUSD <= limitInUSD, "transfer-limit-exceeded");

        _storage.addSpending(valueInUSD);

        emit Spent(valueInUSD, now);
    }

    function _addERC20Spending(
        address token,
        uint256 value,
        uint256 numberOfWitnessSignatures
    ) internal {
        uint256 valueInUSD = _priceFeed().erc20PriceInUSD(token, value);
        uint256 limitInUSD = _storage.transferCapacityInUSD(numberOfWitnessSignatures);
        require(valueInUSD <= limitInUSD, "transfer-limit-exceeded");

        _storage.addSpending(valueInUSD);

        emit Spent(valueInUSD, now);
    }

    function _priceFeed() internal view returns (IPriceFeed) {
        return IPriceFeed(resolveENS(keccak256(abi.encodePacked("price-feed-v0"))));
    }

    function label() public override view returns (bytes32) {
        return _storage.label();
    }

    function nonce() public override view returns (uint256) {
        return _storage.nonce();
    }

    function signingRequirements(bytes4 methodId)
        public
        override
        view
        returns (Storage.SigningRequirements memory)
    {
        return _storage.signingRequirements(methodId);
    }

    function securityPeriod(bytes4 methodId)
        public
        override
        view
        returns (Storage.SecurityPeriod memory)
    {
        return _storage.securityPeriod(methodId);
    }

    function lastExecutionTime(bytes4 selector) public override view returns (uint256) {
        return _storage.lastExecutionTime(selector);
    }

    function resolveENS(bytes32 subdomain) public override view returns (address) {
        address resolver = _ensGateway.resolverOfSubdomain(subdomain);
        return Resolver(resolver).addr(_ensGateway.subdomainNode(subdomain));
    }

    /**
     * @notice If the signature was signed by the owner it returns 0x1626ba7e, otherwise 0xffffffff
     *
     * bytes4(keccak256("isValidSignature(bytes32,bytes)") = 0x1626ba7e
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        public
        override
        view
        returns (bytes4)
    {
        if (_storage.isValidOwnerSignature(hash, signature)) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @notice Checks if the signature was signed by the owner
     *
     * @param hash hashed message of calling a method
     * @param signature signed result of hash by the owner
     */
    function isValidOwnerSignature(bytes32 hash, bytes memory signature)
        public
        override
        view
        returns (bool)
    {
        return _storage.isValidOwnerSignature(hash, signature);
    }

    /**
     * @notice Checks if all signatures were signed by a subset of distinct witnesses
     *
     * @param hash hashed message of calling a method
     * @param signatures signed results of hash by witnesses
     */
    function areValidWitnessSignatures(bytes32 hash, bytes[] memory signatures)
        public
        override
        view
        returns (bool)
    {
        return _storage.areValidWitnessSignatures(hash, signatures);
    }
}
