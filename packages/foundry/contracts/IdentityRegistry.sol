//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract IdentityRegistry is OwnableUpgradeable, UUPSUpgradeable {
    mapping(string => address) public identityTagToResolver;

    mapping(address => bool) public resolverExists;

    error AddressCantBeZero();
    error IdentityTagCantBeEmpty();

    event ResolverAdded(string identityTag, address resolverContract);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function setResolver(string calldata identityTag, address resolverContract) public onlyOwner {
        if (resolverContract == address(0)) revert AddressCantBeZero();
        if (bytes(identityTag).length == 0) revert IdentityTagCantBeEmpty();

        // Update mapping
        identityTagToResolver[identityTag] = resolverContract;

        if (!resolverExists[resolverContract]) {
            resolverExists[resolverContract] = true;
            emit ResolverAdded(identityTag, resolverContract);
        }
    }

    function getResolver(string calldata identityTag) public view returns (address) {
        return identityTagToResolver[identityTag];
    }
}
