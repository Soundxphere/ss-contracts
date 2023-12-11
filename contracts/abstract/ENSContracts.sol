// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ENSRegistry {
    function setOwner(bytes32 node, address owner) public virtual;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) public virtual;

    function setResolver(bytes32 node, address resolver) public virtual;

    function owner(bytes32 node) public view virtual returns (address);

    function resolver(bytes32 node) public view virtual returns (address);
}

abstract contract ENSResolver {
    function setAddr(bytes32 node, address addr) public virtual;

    function addr(bytes32 node) public view virtual returns (address);
}
