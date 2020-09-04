// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

/**
 * @notice Implements https://eips.ethereum.org/EIPS/eip-1822
 * EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
 */
contract Proxy {
    event ETHReceived(address indexed sender, uint256 indexed value);

    // keccak256("PROXIABLE") = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
    bytes32
        private constant UUID = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    constructor(address implementation) public {
        assembly {
            sstore(UUID, implementation)
        }
    }

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        assembly {
            let impl := sload(UUID)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}
