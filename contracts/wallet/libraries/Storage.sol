// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library Storage {
    using ECDSA for bytes32;
    using Address for address;

    uint256 private constant MINIMUM_TRANSFER_LIMIT_IN_USD = 10**20; // 100 USD
    uint256 private constant TRANSFER_CAPACITY_RESET_PERIOD = 24 hours;

    struct Signatures {
        bytes owner;
        bytes[] witnesses;
    }

    struct SigningRequirements {
        bool owner;
        uint256 witnesses;
    }

    struct SecurityPeriod {
        uint256 time;
        bytes4[] dependencies;
    }

    struct Spending {
        uint256 valueInUSD;
        uint256 timestamp;
    }

    struct Data {
        uint256 _nonce;
        mapping(bytes4 => SigningRequirements) _signingRequirements;
        mapping(bytes4 => SecurityPeriod) _securityPeriods;
        mapping(bytes4 => uint256) _lastExecutionTime;
        bytes32 _label;
        address _owner;
        mapping(address => bytes32) _witnessNames;
        address[] _witnesses;
        bool _locked;
        Spending[] _spending;
    }

    function label(Data storage self) public view returns (bytes32) {
        return self._label;
    }

    function setLabel(Data storage self, bytes32 label_) public {
        self._label = label_;
    }

    function nonce(Data storage self) public view returns (uint256) {
        return self._nonce;
    }

    function incrementNonce(Data storage self) public {
        self._nonce += 1;
    }

    function signingRequirements(Data storage self, bytes4 methodId)
        public
        view
        returns (SigningRequirements storage)
    {
        return self._signingRequirements[methodId];
    }

    function setSigningRequirements(
        Data storage self,
        bytes4 methodId,
        bool ownerRequired,
        uint256 witnessesRequired
    ) public {
        self._signingRequirements[methodId].owner = ownerRequired;
        self._signingRequirements[methodId].witnesses = witnessesRequired;
    }

    function securityPeriod(Data storage self, bytes4 methodId)
        public
        view
        returns (SecurityPeriod storage)
    {
        return self._securityPeriods[methodId];
    }

    function setSecurityPeriod(
        Data storage self,
        bytes4 methodId,
        uint256 time,
        bytes4[] memory dependencies
    ) public {
        self._securityPeriods[methodId].time = time;
        self._securityPeriods[methodId].dependencies = dependencies;
    }

    /**
     * @notice Last executed timestamp that the method of 'selector' called
     */
    function lastExecutionTime(Data storage self, bytes4 selector) public view returns (uint256) {
        return self._lastExecutionTime[selector];
    }

    function updateLastExecutionTime(Data storage self, bytes4 selector) public {
        self._lastExecutionTime[selector] = now;
    }

    /**
     * @notice The owner
     */
    function owner(Data storage self) public view returns (address) {
        return self._owner;
    }

    function transferOwnership(Data storage self, address newOwner) public {
        require(newOwner != address(0), "invalid-owner");
        require(newOwner != address(this), "wallet-cannot-be-owner");
        require(self._witnessNames[newOwner] == bytes32(0), "witness-cannot-be-owner");
        address previousOwner = self._owner;
        require(previousOwner != newOwner, "already-owner");
        self._owner = newOwner;
    }

    /**
     * @notice Witness names for their addresses
     */
    function witnessNames(Data storage self, address addr) public view returns (bytes32) {
        return self._witnessNames[addr];
    }

    /**
     * @notice Witness addresses
     */
    function witnesses(Data storage self, uint256 index) public view returns (address) {
        return self._witnesses[index];
    }

    function numberOfWitnesses(Data storage self) public view returns (uint256) {
        return self._witnesses.length;
    }

    function addWitness(
        Data storage self,
        address addr,
        bytes32 name
    ) public {
        require(addr != address(0), "invalid-address");
        require(name != bytes32(0), "invalid-name");
        require(addr != address(this), "cannot-add-wallet");
        require(self._owner != addr, "cannot-add-owner");
        require(self._witnessNames[addr] == bytes32(0), "witness-exists");

        self._witnessNames[addr] = name;
        self._witnesses.push(addr);
    }

    function removeWitness(Data storage self, address addr) public {
        require(addr != address(0), "invalid-address");
        require(self._witnesses.length > 1, "at-least-one-witness-required");
        require(self._witnessNames[addr] != bytes32(0), "not-witness");

        delete self._witnessNames[addr];
        for (uint256 i = 0; i < self._witnesses.length; i++) {
            if (self._witnesses[i] == addr) {
                self._witnesses[i] = self._witnesses[self._witnesses.length - 1];
                self._witnesses.pop();
                break;
            }
        }
    }

    function locked(Data storage self) public view returns (bool) {
        return self._locked;
    }

    function setLocked(Data storage self, bool newLocked) public {
        self._locked = newLocked;
    }

    /**
     * @notice How much an owner can spend with 0 witness
     *
     * For each signature of a witness is offered, limit is multiplied by 10
     */
    function minimumTransferLimitInUSD(Data storage) public pure returns (uint256) {
        return MINIMUM_TRANSFER_LIMIT_IN_USD;
    }

    function transferCapacityResetPeriod(Data storage) public pure returns (uint256) {
        return TRANSFER_CAPACITY_RESET_PERIOD;
    }

    /**
     * @notice Transfer capacity available in USD
     *
     * 10**18 = 1 USD
     */
    function transferCapacityInUSD(Data storage self, uint256 numberOfWitnessSignatures)
        public
        view
        returns (uint256)
    {
        uint256 limitInUSD = MINIMUM_TRANSFER_LIMIT_IN_USD * (10**numberOfWitnessSignatures);
        uint256 spendingInUSD = cumulativeSpendingInUSD(self, now - TRANSFER_CAPACITY_RESET_PERIOD);
        return limitInUSD > spendingInUSD ? limitInUSD - spendingInUSD : 0;
    }

    /**
     * @notice Cumulative value spent in USD after 'fromTimestamp'
     g
     */
    function cumulativeSpendingInUSD(Data storage self, uint256 fromTimestamp)
        public
        view
        returns (uint256)
    {
        uint256 spending = 0;
        if (self._spending.length > 0) {
            for (uint256 i = self._spending.length; i > 0; i--) {
                Spending storage spent = self._spending[i - 1];
                if (spent.timestamp < fromTimestamp) {
                    break;
                }
                spending += spent.valueInUSD;
            }
        }
        return spending;
    }

    function addSpending(Data storage self, uint256 valueInUSD) public {
        Spending storage spent = self._spending.push();
        spent.valueInUSD = valueInUSD;
        spent.timestamp = now;
    }

    function isValidOwnerSignature(
        Data storage self,
        bytes32 hash,
        bytes memory signature
    ) public view returns (bool) {
        return _verify(hash, self._owner, signature);
    }

    function areValidWitnessSignatures(
        Data storage self,
        bytes32 hash,
        bytes[] memory signatures
    ) public view returns (bool) {
        if (_duplicate(signatures)) {
            return false;
        }
        for (uint256 i = 0; i < signatures.length; i++) {
            bytes memory signature = signatures[i];
            bool valid = false;
            for (uint256 j = 0; j < self._witnesses.length; j++) {
                if (_verify(hash, self._witnesses[j], signature)) {
                    valid = true;
                    break;
                }
            }
            if (!valid) {
                return false;
            }
        }
        return true;
    }

    /**
     * @return true if array has duplicate items, false otherwise
     */
    function _duplicate(bytes[] memory array) private pure returns (bool) {
        bytes32[] memory hashes = new bytes32[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            hashes[i] = keccak256(array[i]);
        }
        for (uint256 i = 0; i < hashes.length; i++) {
            for (uint256 j = i + 1; j < hashes.length; j++) {
                if (hashes[i] == hashes[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function _verify(
        bytes32 hash,
        address signer,
        bytes memory signature
    ) public view returns (bool) {
        if (signer.isContract()) {
            // Consider the signer as an EIP-1271 compatible contract
            // bytes4(keccak256("isValidSignature(bytes32,bytes)")) = 0x1626ba7e
            bytes4 magicValue = 0x1626ba7e;
            (bool success, bytes memory data) = signer.staticcall(abi.encodePacked(magicValue));
            if (success) {
                bytes4 returned = abi.decode(data, (bytes4));
                return magicValue == returned;
            } else {
                return false;
            }
        } else {
            // Try EIP-712
            bool v = signer == hash.recover(signature);
            if (v) {
                return true;
            } else {
                // Consider signed by web3.eth_sign
                hash = hash.toEthSignedMessageHash();
                return signer == hash.recover(signature);
            }
        }
    }
}
