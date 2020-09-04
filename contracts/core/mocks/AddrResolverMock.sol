// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

contract AddrResolverMock {
    uint256 private constant COIN_TYPE_ETH = 60;

    address private _owner;
    mapping(bytes32 => mapping(uint256 => bytes)) private _addresses;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);

    constructor() public {
        _owner = msg.sender;
    }

    function isAuthorised() internal view returns (bool) {
        return msg.sender == _owner;
    }

    modifier authorised() {
        require(isAuthorised(), "not-authorised");
        _;
    }

    function setAddr(bytes32 node, address a) public authorised {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) public authorised {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint256 coinType) public view returns (bytes memory) {
        return _addresses[node][coinType];
    }

    function bytesToAddress(bytes memory b) internal pure returns (address payable a) {
        require(b.length == 20, "");
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}
