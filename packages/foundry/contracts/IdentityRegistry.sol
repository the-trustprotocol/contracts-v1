//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract IdentityRegistry is OwnableUpgradeable, UUPSUpgradeable {
    mapping(string => address) private identityTagToResolver;

    mapping(address => bool) private resolverExists;

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

    function setResolver(string calldata identityTag, address resolverContract) external onlyOwner {
        require(resolverContract != address(0), "Invalid resolver address");
        require(bytes(identityTag).length > 0, "Identity tag cannot be empty");

        // Update mapping
        identityTagToResolver[identityTag] = resolverContract;

        if (!resolverExists[resolverContract]) {
            resolverExists[resolverContract] = true;
            emit ResolverAdded(identityTag, resolverContract);
        }
    }



    function getResolver(string calldata identityTag) external view returns (address) {
        return identityTagToResolver[identityTag];
    }
}
