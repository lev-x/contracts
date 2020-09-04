// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./Proxy.sol";

contract ProxyFactory {
    using ECDSA for bytes32;

    mapping(address => bool) private _proxies;

    event ProxyCreated(address indexed implementation, address proxy);

    function isProxy(address addr) public view returns (bool) {
        return _proxies[addr];
    }

    function createProxy(
        address implementation,
        bytes32 salt,
        bytes memory initializeData,
        bytes memory signature
    ) public returns (address payable addr) {
        require(_proxies[addr] == false, "proxy-already-created");
        _proxies[addr] = true;

        address signer = createProxyHash(implementation, salt, initializeData)
            .toEthSignedMessageHash()
            .recover(signature);
        bytes32 signerSalt = keccak256(abi.encodePacked(signer, salt));
        bytes memory code = abi.encodePacked(type(Proxy).creationCode, abi.encode(implementation));
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), signerSalt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = addr.call(initializeData);
        require(success, "failed-to-initialize");

        emit ProxyCreated(implementation, addr);
    }

    function createProxyHash(
        address implementation,
        bytes32 salt,
        bytes memory initializeData
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    address(this),
                    this.createProxy.selector,
                    implementation,
                    salt,
                    initializeData
                )
            );
    }
}
