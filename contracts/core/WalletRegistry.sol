// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./mixins/Initializable.sol";
import "./mixins/Ownable.sol";
import "./interfaces/IWalletRegistry.sol";

contract WalletRegistry is Initializable, Ownable, IWalletRegistry {
    struct Implementation {
        bytes32 versionName;
        address addr;
    }

    Implementation[] internal _wallets;

    function initialize(address owner) public initializer {
        _initialize(owner);
    }

    function versionNames() public override returns (bytes32[] memory) {
        bytes32[] memory v = new bytes32[](_wallets.length);
        for (uint256 i = 0; i < _wallets.length; i++) {
            v[i] = _wallets[i].versionName;
        }
        return v;
    }

    function register(bytes32 versionName, address addr) public override onlyOwner {
        require(versionName != bytes32(0), "version-must-not-be-empty");
        require(addr != address(0), "address-must-not-be-zero");

        Implementation storage wallet = _wallets.push();
        wallet.versionName = versionName;
        wallet.addr = addr;
    }

    function latest() public override view returns (bytes32 versionName, address addr) {
        uint256 length = _wallets.length;
        if (length > 0) {
            Implementation storage wallet = _wallets[length - 1];
            return (wallet.versionName, wallet.addr);
        } else {
            return (0, address(0));
        }
    }

    function queryWithAddress(address addr) public override view returns (bytes32 versionName) {
        for (uint256 i = 0; i < _wallets.length; i++) {
            Implementation storage wallet = _wallets[i];
            if (wallet.addr == addr) {
                return wallet.versionName;
            }
        }
        return 0;
    }

    function queryWithVersionName(bytes32 versionName) public override view returns (address add) {
        for (uint256 i = 0; i < _wallets.length; i++) {
            Implementation storage wallet = _wallets[i];
            if (wallet.versionName == versionName) {
                return wallet.addr;
            }
        }
        return address(0);
    }
}
