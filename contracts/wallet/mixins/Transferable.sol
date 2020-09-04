// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseMixin.sol";
import "./interfaces/ITransferable.sol";
import "./interfaces/IAuthorizable.sol";

abstract contract Transferable is BaseMixin, ITransferable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function _initialize() internal virtual {
        _storage.setSigningRequirements(this.transferETH.selector, true, 0);
        _storage.setSigningRequirements(this.transferERC20.selector, true, 0);

        bytes4[] memory dependencies = new bytes4[](1);
        dependencies[0] = IAuthorizable.transferOwnership.selector;
        _storage.setSecurityPeriod(this.transferETH.selector, 24 hours, dependencies);
        _storage.setSecurityPeriod(this.transferERC20.selector, 24 hours, dependencies);
    }

    /**
     * @notice How much an owner can spend with 0 witness
     *
     * For each signature of a witness is offered, limit is multiplied by 10
     */
    function minimumTransferLimitInUSD() public override view returns (uint256) {
        return _storage.minimumTransferLimitInUSD();
    }

    function transferCapacityResetPeriod() public override view returns (uint256) {
        return _storage.transferCapacityResetPeriod();
    }

    /**
     * @notice Transfer capacity available in USD
     *
     * 10**18 = 1 USD
     */
    function transferCapacityInUSD(uint256 numberOfWitnessSignatures)
        public
        override
        view
        returns (uint256)
    {
        return _storage.transferCapacityInUSD(numberOfWitnessSignatures);
    }

    function cumulativeSpendingInUSD(uint256 fromTimestamp) public override view returns (uint256) {
        return _storage.cumulativeSpendingInUSD(fromTimestamp);
    }

    /**
     * @notice Transfers 'value' amount of ETH to 'to'
     *
     * @param to receiver address
     * @param value amount of ETH
     */
    function transferETH(
        address payable to,
        uint256 value,
        Storage.Signatures memory signatures
    ) public override whenInitialized whenNotLocked {
        require(value <= address(this).balance, "not-enough-balance");

        _ensureSecurityPeriodPassed(this.transferETH.selector);
        _ensureSignaturesValid(this.transferETH.selector, transferETHHash(to, value), signatures);

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.transferETH.selector);

        _addETHSpending(value, signatures.witnesses.length);
        to.transfer(value);

        emit ETHTransferred(to, value);
    }

    /**
     * @return a hash used to generate signature to properly call 'transferETH()'
     */
    function transferETHHash(address payable to, uint256 value)
        public
        override
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.transferETH.selector,
                    to,
                    value
                )
            );
    }

    /**
     * @notice Transfers 'value' amount of ERC20 'token' to 'to'
     *
     * @param token ERC20 address
     * @param to receiver address
     * @param value amount of ERC20
     */
    function transferERC20(
        address token,
        address to,
        uint256 value,
        Storage.Signatures memory signatures
    ) public override whenInitialized whenNotLocked {
        require(value <= IERC20(token).balanceOf(address(this)), "not-enough-balance");

        _ensureSecurityPeriodPassed(this.transferERC20.selector);
        _ensureSignaturesValid(
            this.transferERC20.selector,
            transferERC20Hash(token, to, value),
            signatures
        );

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.transferERC20.selector);

        _addERC20Spending(token, value, signatures.witnesses.length);
        IERC20(token).safeTransfer(to, value);
    }

    /**
     * @return a hash used to generate signature to properly call 'transferERC20()'
     */
    function transferERC20Hash(
        address token,
        address to,
        uint256 value
    ) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.transferERC20.selector,
                    token,
                    to,
                    value
                )
            );
    }
}
