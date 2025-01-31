// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../contracts/factories/UserFactory.sol";

import "../contracts/settings/UserFactorySettings.sol";
import "../contracts/settings/UserSettings.sol";

import "../contracts/IdentityRegistry.sol";

import "../contracts/Registry.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract UserFactoryTest is Test {
  address owner = makeAddr("owner");
  UserFactory public impl;
  ERC1967Proxy public proxy;
  UserFactory public userFactory;

  UserFactorySettings public settingsImpl;
  ERC1967Proxy public settingsProxy;
  UserFactorySettings public settings;

  UserSettings public userSettingsImpl;
  ERC1967Proxy public userSettingsProxy;
  UserSettings public userSettings;

  IdentityRegistry public identityRegistryImpl;
  ERC1967Proxy public identityRegistryProxy;
  IdentityRegistry public identityRegistry;

  Registry public registryImpl;
  ERC1967Proxy public registryProxy;
  Registry public registry;


  function setUp() public {
    vm.startPrank(owner);


    settingsImpl = new UserFactorySettings();
    settingsProxy = new ERC1967Proxy(address(settingsImpl), "");
    settings = UserFactorySettings(address(settingsProxy));

    userSettingsImpl = new UserSettings();
    userSettingsProxy = new ERC1967Proxy(address(userSettingsImpl), "");
    userSettings = UserSettings(address(userSettingsProxy));

    registryImpl = new Registry();
    registryProxy = new ERC1967Proxy(address(registryImpl), "");
    registry = Registry(address(registryProxy));



    impl = new UserFactory();
    proxy = new ERC1967Proxy(address(impl), abi.encodeCall(UserFactory.initialize, (address(settings), address(registry), address(userSettings))));
    userFactory = UserFactory(address(proxy));

    identityRegistryImpl = new IdentityRegistry();
    identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), "");
    identityRegistry = IdentityRegistry(address(identityRegistryProxy));
    vm.stopPrank();
  }

  function test_createUserWithoutFees() public {
    vm.startPrank(owner);
    address user = userFactory.createUser(address(identityRegistry));
    assertEq(user, registry.addressToUserContracts(owner));
    vm.stopPrank();
  }

}