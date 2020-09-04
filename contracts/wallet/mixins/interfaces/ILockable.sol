// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../../libraries/Storage.sol";

interface ILockable {
    event Locked();
    event Unlocked();

    function locked() external view returns (bool);

    function lock(Storage.Signatures calldata signatures) external;

    function lockHash() external view returns (bytes32);

    function unlock(Storage.Signatures calldata signatures) external;

    function unlockHash() external view returns (bytes32);
}
