// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./BaseMixin.sol";
import "./interfaces/IExecutable.sol";
import "./interfaces/IAuthorizable.sol";

abstract contract Executable is BaseMixin, IExecutable {
    using SafeERC20 for IERC20;

    struct ERC20Approval {
        address token;
        address spender;
    }
    ERC20Approval[] internal _approvals;

    function _initialize() internal virtual {
        _storage.setSigningRequirements(this.execute.selector, true, 0);

        bytes4[] memory dependencies = new bytes4[](2);
        dependencies[0] = IAuthorizable.transferOwnership.selector;
        _storage.setSecurityPeriod(this.execute.selector, 24 hours, dependencies);
    }

    /**
     * @notice Executes arbitrary contract functions
     * If 'ERC20.approve()'s were called in the batched executions,
     * then all the amounts of the approved tokens need to be spent by the end of the call
     *
     * @param targets contract addresses to be executed for each execution
     * @param values amount of ETH for each execution
     * @param data methodID + args for each execution
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data,
        Storage.Signatures memory signatures
    ) public override payable whenInitialized whenNotLocked returns (bytes[] memory) {
        require(
            targets.length == values.length && values.length == data.length,
            "different-params-length"
        );
        _ensureSecurityPeriodPassed(this.execute.selector);
        _ensureSignaturesValid(
            this.execute.selector,
            executeHash(targets, values, data),
            signatures
        );

        _storage.incrementNonce();
        _storage.updateLastExecutionTime(this.execute.selector);

        bytes[] memory returned = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            returned[i] = _execute(targets[i], values[i], data[i], signatures);
        }
        _ensureApprovedERC20SpentAll();
        return returned;
    }

    function _execute(
        address target,
        uint256 value,
        bytes memory data,
        Storage.Signatures memory signatures
    ) internal nonReentrant returns (bytes memory) {
        require(target != address(0), "invalid-target");
        require(value <= address(this).balance, "not-enough-balance");

        emit Executed(target, value, data);

        if (value > 0) {
            _addETHSpending(value, signatures.witnesses.length);
        }
        if (data.length > 0) {
            (bytes4 methodId, bytes memory args) = abi.decode(data, (bytes4, bytes));
            if (methodId == IERC20.transfer.selector) {
                (address to, uint256 amount) = abi.decode(args, (address, uint256));
                _addERC20Spending(target, amount, signatures.witnesses.length);
                IERC20(target).safeTransfer(to, value);
                return bytes("");
            } else if (methodId == IERC20.approve.selector) {
                (address to, uint256 amount) = abi.decode(args, (address, uint256));
                _addERC20Spending(target, amount, signatures.witnesses.length);
                _addERC20Approval(target, to);
                IERC20(target).approve(to, value);
                return bytes("");
            } else {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, bytes memory returned) = target.call{value: value}(data);
                if (success) {
                    return returned;
                } else {
                    if (returned.length > 0) {
                        assembly {
                            let returned_size := mload(returned)
                            revert(add(32, returned), returned_size)
                        }
                    } else {
                        revert("external-call-failed");
                    }
                }
            }
        } else {
            _addETHSpending(value, signatures.witnesses.length);
            payable(target).transfer(value);
            return bytes("");
        }
    }

    function _addERC20Approval(address token, address spender) private {
        if (spender == resolveENS(keccak256(abi.encodePacked("tx-relayer-v0")))) {
            return;
        }
        ERC20Approval storage approval = _approvals.push();
        approval.token = token;
        approval.spender = spender;
    }

    function _ensureApprovedERC20SpentAll() private {
        for (uint256 i = 0; i < _approvals.length; i++) {
            ERC20Approval storage approval = _approvals[i];
            require(
                IERC20(approval.token).allowance(address(this), approval.spender) == 0,
                "approved-erc20-not-spent"
            );
        }
        delete _approvals;
    }

    /**
     * @return a hash used to generate signature to properly call 'execute()'
     */
    function executeHash(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    _storage.nonce(),
                    this.execute.selector,
                    targets,
                    values,
                    abi.encode(data)
                )
            );
    }
}
