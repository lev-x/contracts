// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../../libraries/Storage.sol";

interface ITransferable {
    event ETHTransferred(address indexed to, uint256 indexed value);

    function minimumTransferLimitInUSD() external view returns (uint256);

    function transferCapacityResetPeriod() external view returns (uint256);

    function transferCapacityInUSD(uint256 numberOfWitnessSignatures)
        external
        view
        returns (uint256);

    function cumulativeSpendingInUSD(uint256 fromTimestamp) external view returns (uint256);

    function transferETH(
        address payable to,
        uint256 value,
        Storage.Signatures calldata signatures
    ) external;

    function transferETHHash(address payable to, uint256 value) external view returns (bytes32);

    function transferERC20(
        address token,
        address to,
        uint256 value,
        Storage.Signatures calldata signatures
    ) external;

    function transferERC20Hash(
        address token,
        address to,
        uint256 value
    ) external view returns (bytes32);
}
