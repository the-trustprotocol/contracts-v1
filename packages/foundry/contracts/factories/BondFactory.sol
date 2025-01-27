// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../Bond.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract BondFactory is Ownable2StepUpgradeable, UUPSUpgradeable {
    using Clones for address;

    address public implementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _bondImplementation) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        implementation = _bondImplementation;
    }

    function createBond(
        address _asset,
        address _user1,
        address _user2,
        uint256 _user1Amount,
        address _aavePoolAddress
    ) external onlyOwner returns (address) {

        address newBond = implementation.clone();

        Bond(newBond).initialize(
            _asset,
            _user1,
            _user2,
            _user1Amount,
            _aavePoolAddress
        );
        return newBond;
    }

    function updateImplementation(address _newImplementation) external onlyOwner {
        implementation = _newImplementation;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
