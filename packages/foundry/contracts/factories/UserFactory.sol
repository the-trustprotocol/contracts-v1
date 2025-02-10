// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IUserFactory } from "../interfaces/IUserFactory.sol";
import { IFeeSettings } from "../interfaces/IFeeSettings.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { IUser } from "../interfaces/IUser.sol";
import { User } from "../User.sol";
import { IIdentityRegistry } from "../interfaces/IIdentityRegistry.sol";
import { IUserFactorySwapables } from "../interfaces/IUserFactorySwapables.sol";

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

  function createUserWithBond(address user1,address user2,uint256 initialAmount,address bondFactoryAddress,address yieldProviderService) public payable returns (address){
    User protocolUser1 = User(createUserOnBehalf(user1));
    User protocolUser2 = User(createUserOnBehalf(user2));
    protocolUser1.createBond(_bond, bondFactoryAddress, yieldProviderService);
    


  }

  function createUserOnBehalf(address user) public payable override returns (address) {
    settings.collectFees{ value: msg.value }(msg.sender, msg.value, msg.sig);

    if(registry.addressToUserContracts(user) == address(0)){
      IUser protocolUser = new User(address(identityRegistry), address(userSettings));
      address userAddress = address(protocolUser);
      registry.setUserContract(user, userAddress);
      emit UserCreated(user, userAddress);
      return userAddress;
    }
    return registry.addressToUserContracts(user); 
  }

    // function createUserWithBond(address user1,address user2,uint256 initialAmount) public payable returns (address){
    //   bool user1Exists = registry.addressToUserContracts(user1) != address(0);
    //   bool user2Exists = registry.addressToUserContracts(user2) != address(0);
    //   if(!user1Exists){
    //     createUserOnBehalf(user1);
    //   }
    //   if(!user2Exists){
    //     createUserOnBehalf(user2);
    //   }

    // }

    function createUserOnBehalf(address user) public payable override returns (address) {
        settings.collectFees{ value: msg.value }(msg.sender, msg.value, msg.sig);
        IUser userContract = new User(address(identityRegistry), address(userSettings));
        address userAddress = address(userContract);
        registry.setUserContract(user, userAddress);
        emit UserCreated(user, userAddress);
        return userAddress;
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
