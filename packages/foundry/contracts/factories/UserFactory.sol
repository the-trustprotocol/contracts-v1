// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IUserFactory } from "../interfaces/IUserFactory.sol";
import { IFeeSettings } from "../interfaces/IFeeSettings.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { IUser } from "../interfaces/IUser.sol";
import { User } from "../User.sol";

contract UserFactory is IUserFactory, Ownable2StepUpgradeable, UUPSUpgradeable {
    IFeeSettings public settings;
    IRegistry public registry;
    IFeeSettings public userSettings;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _settings, address _registry, address _userSettings) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        settings = IFeeSettings(_settings);
        registry = IRegistry(_registry);
        userSettings = IFeeSettings(_userSettings);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function createUser(address _identityRegistry) public payable returns (address) {
        // Collect fees
        settings.collectFees{ value: msg.value }(msg.sender, msg.value, msg.sig);

        IUser user = new User(_identityRegistry, address(userSettings));
        address userAddress = address(user);
        registry.setUserContract(msg.sender, userAddress);
        emit UserCreated(msg.sender, userAddress);
        return userAddress;
    }

    function attestationManager() external view override returns (address) { }
}
