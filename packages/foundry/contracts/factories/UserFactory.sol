// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IUserFactory } from "../interfaces/IUserFactory.sol";
import { IFeeSettings } from "../interfaces/IFeeSettings.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { IUser } from "../interfaces/IUser.sol";

import { IYieldProviderService } from "../interfaces/IYieldProviderService.sol";
import { User } from "../User.sol";
import { IIdentityRegistry } from "../interfaces/IIdentityRegistry.sol";
import { IUserFactorySwapables } from "../interfaces/IUserFactorySwapables.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserFactory is IUserFactory, IUserFactorySwapables, Ownable2StepUpgradeable, UUPSUpgradeable {
    IFeeSettings public settings;
    IRegistry public registry;
    IFeeSettings public userSettings;
    IIdentityRegistry public identityRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _settings, address _registry, address _userSettings, address _identityRegistry)
        public
        initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        settings = IFeeSettings(_settings);
        registry = IRegistry(_registry);
        userSettings = IFeeSettings(_userSettings);
        identityRegistry = IIdentityRegistry(_identityRegistry);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function createUserWithBond(
        address user1,
        address user2,
        uint256 initialAmount,
        address bondFactoryAddress,
        address yieldProviderService
    ) public payable returns (address) {
        (address protocolUser1Address, bool protocolUser1IsNew) = createUserOnBehalf(user1);
        (address protocolUser2Address, bool protocolUser2IsNew) = createUserOnBehalf(user2);
        User protocolUser1 = User(protocolUser1Address);
        User protocolUser2 = User(protocolUser2Address);
        if (initialAmount > 0) {
            IYieldProviderService yieldProviderServiceContract = IYieldProviderService(yieldProviderService);
            IERC20(yieldProviderServiceContract.depositToken()).transferFrom(msg.sender, address(this), initialAmount);
            IERC20(yieldProviderServiceContract.depositToken()).approve(protocolUser1Address, initialAmount);
            protocolUser1.createBond(
                user2,
                yieldProviderServiceContract.depositToken(),
                yieldProviderService,
                initialAmount,
                bondFactoryAddress
            );
        }
        if (protocolUser1IsNew) {
            protocolUser1.transferOwnership(user1);
        }
        if (protocolUser2IsNew) {
            protocolUser2.transferOwnership(user2);
        }
    }

    function createUser(address user) public payable returns (address) {
        (address protocolUserAddress, bool protocolUserIsNew) = createUserOnBehalf(user);
        User protocolUser = User(protocolUserAddress);
        if (protocolUserIsNew) {
            protocolUser.transferOwnership(user);
        }
        return protocolUserAddress;
    }

    function createUserOnBehalf(address user) private returns (address, bool) {
        settings.collectFees{ value: msg.value }(msg.sender, msg.value, msg.sig);

        if (registry.addressToUserContracts(user) == address(0)) {
            IUser protocolUser =
                new User(address(this), address(identityRegistry), address(userSettings), address(this));
            address userAddress = address(protocolUser);
            registry.setUserContract(user, userAddress);
            emit UserCreated(user, userAddress);
            return (userAddress, true);
        }
        return (registry.addressToUserContracts(user), false);
    }

    function attestationManager() external view override returns (address) { }

    function swapUserFactorySettings(address _newFactorySettings) public override onlyOwner {
        settings = IFeeSettings(_newFactorySettings);
    }

    function swapRegistry(address _registry) public override onlyOwner {
        registry = IRegistry(_registry);
    }

    function swapIdentityRegistry(address _newIdentityRegistry) public override onlyOwner {
        identityRegistry = IIdentityRegistry(_newIdentityRegistry);
    }

    function swapUserSettings(address _newUserSettings) public override onlyOwner {
        userSettings = IFeeSettings(_newUserSettings);
    }
}
