// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "../mixins/Initializable.sol";
import "../interfaces/IENSGateway.sol";
import "./AddrResolverMock.sol";

contract ENSGatewayMock is Initializable, IENSGateway {
    mapping(bytes32 => address) internal _owners;
    AddrResolverMock internal _resolver;

    function initialize(address) public initializer {
        _resolver = new AddrResolverMock();
    }

    function ens() public override view returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function resolver() public override view returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function tld() public override view returns (string memory) {
        return "levx.eth";
    }

    // namehash("levx.eth")
    function tldNode() public override view returns (bytes32) {
        return 0xf88903d82aebfe9a5fa03a1a6eb4475330ed9991c9b6ffea0f6d0154a210efbe;
    }

    function subdomainNode(bytes32 label) public override view returns (bytes32) {
        return keccak256(abi.encodePacked(tldNode(), label));
    }

    function ownerOfSubdomain(bytes32 label) public override view returns (address) {
        return _owners[label];
    }

    function resolverOfSubdomain(bytes32) public override view returns (address) {
        return address(_resolver);
    }

    function registerSubdomain(bytes32 label, address addr) public override {
        require(label != bytes32(0), "invalid-label");
        require(addr != address(0), "invalid-addr");
        require(ownerOfSubdomain(label) == address(0), "already-registered");

        _owners[label] = msg.sender;
        _resolver.setAddr(subdomainNode(label), addr);
    }
}
