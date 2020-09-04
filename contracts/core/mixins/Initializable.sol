// SPDX-License-Identifier: MIT
// solhint-disable-next-line max-line-length
// https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/Initializable.sol

pragma solidity ^0.6.8;

contract Initializable {
    bool public initialized;

    bool private initializing;

    modifier initializer() {
        require(initializing || !initialized, "already-initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }
}
