// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@ensdomains/ens/contracts/ENS.sol";
import "@ensdomains/resolver/contracts/Resolver.sol";

import "./mixins/Initializable.sol";
import "./mixins/Ownable.sol";
import "./interfaces/IENSGateway.sol";
import "./interfaces/IENSReverseRegistrar.sol";

contract ENSGateway is Initializable, Ownable, IENSGateway {
    address private _resolver;

    function initialize(address owner) public initializer {
        _initialize(owner);
        _resolver = ENS(ens()).resolver(tldNode());
        require(_resolver != address(0), "resolver-not-set");
    }

    function setTLDOwner(address newOwner) public onlyOwner {
        ENS(ens()).setOwner(tldNode(), newOwner);
    }

    function ens() public override view returns (address) {
        return 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    }

    function resolver() public override view returns (address) {
        return _resolver;
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
        return ENS(ens()).owner(subdomainNode(label));
    }

    function resolverOfSubdomain(bytes32 label) public override view returns (address) {
        return ENS(ens()).resolver(subdomainNode(label));
    }

    function registerSubdomain(bytes32 label, address addr) public override {
        require(label != bytes32(0), "invalid-label");
        require(addr != address(0), "invalid-addr");
        require(ownerOfSubdomain(label) == address(0), "already-registered");

        ENS(ens()).setSubnodeRecord(tldNode(), label, address(this), _resolver, 0);
        Resolver(_resolver).setAddr(subdomainNode(label), addr);

        ENS(ens()).setSubnodeOwner(tldNode(), label, msg.sender);

        emit SubdomainRegistered(label, msg.sender, addr);
    }
}
