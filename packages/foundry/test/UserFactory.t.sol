// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../contracts/factories/UserFactory.sol";

import "../contracts/settings/UserFactorySettings.sol";
import "../contracts/settings/UserSettings.sol";
import "../contracts/IdentityRegistry.sol";
import "../contracts/Registry.sol";
import "../contracts/interfaces/IFeeSettings.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UserFactoryTest is Test {
  address owner = makeAddr("owner");
  address treasury = makeAddr("treasury");

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
    settingsProxy = new ERC1967Proxy(address(settingsImpl),"");
    settings = UserFactorySettings(address(settingsProxy));
    settings.initialize();


    userSettingsImpl = new UserSettings();
    userSettingsProxy = new ERC1967Proxy(address(userSettingsImpl), "");
    userSettings = UserSettings(address(userSettingsProxy));



    registryImpl = new Registry();
    registryProxy = new ERC1967Proxy(address(registryImpl), "");
    registry = Registry(address(registryProxy));
    registry.initialize("1.0");

    identityRegistryImpl = new IdentityRegistry();
    identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), "");
    identityRegistry = IdentityRegistry(address(identityRegistryProxy));

    impl = new UserFactory();
    proxy = new ERC1967Proxy(
      address(impl),
      abi.encodeCall(UserFactory.initialize, (address(settings), address(registry), address(userSettings),address(identityRegistry)))
    );
    userFactory = UserFactory(address(proxy));
    registry.addTrustedUpdater(address(userFactory));
    vm.stopPrank();
  }

  function test_createUserWithoutFees() public {
    vm.prank(owner);
    address user = userFactory.createUser();
    assertEq(user, registry.addressToUserContracts(owner));
    vm.stopPrank();
  }

  // function test_createUserWithFlatFees(
  //   uint256 flatFee,
  //   address treasury
  // ) public {
  //   vm.startPrank(owner);
  //   vm.deal(owner, 300 ether);
  //   vm.assume(treasury != address(0));
  //   vm.assume(flatFee > 0.1 ether && flatFee < 200 ether); 
  //   bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");

  //   settings.registerFunctionFees(functionBytes, flatFee, 0, address(0), treasury);
  //   (uint256 _flatFee, uint256 percentageFee, address tokenAddress, address _treasury, bool _isRegistered) = settings.functionFees(functionBytes);
  //   assertEq(_flatFee, flatFee);
  //   assertEq(percentageFee, 0);
  //   assertEq(tokenAddress, address(0));
  //   assertEq(_treasury, treasury);
  //   assertEq(_isRegistered, true);

  //   address user = userFactory.createUser{ value: flatFee + 1 ether}();

  //   assertEq(treasury.balance, flatFee);
  //   assertEq(user, registry.addressToUserContracts(owner));
  //   vm.stopPrank();
  // }
  function test_createUserWithFlatFees() public {
    vm.startPrank(owner);
    vm.deal(owner,2 ether);
    bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");
    settings.registerFunctionFees(functionBytes, 1 ether, 0, address(0), treasury);
    address user = userFactory.createUser{ value: 2 ether}();
    assertEq(treasury.balance,1 ether);
    assertEq(owner.balance,1 ether);
    vm.stopPrank();
  }
  function test_createUserWithPercentageFees() public {
    vm.startPrank(owner);
    vm.deal(owner,1 ether);
    uint256 percentage = 100;
    uint256 totalFee = 1 ether;
    bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");
    settings.registerFunctionFees(functionBytes, 0, percentage, address(0), treasury);
    uint256 expectedFee = (totalFee * percentage) / 1000;
    address user = userFactory.createUser{ value: totalFee}();
    console.log("treasury.balance",treasury.balance);
    console.log("expectedFee",expectedFee);
    console.log("owner.balance",owner.balance);
    assertEq(treasury.balance,expectedFee);
    assertEq(owner.balance,totalFee - expectedFee);
    vm.stopPrank();
  }

  // function test_createUserWithPercentageFees(
  //   uint256 percentageFee,
  //   address treasury
  // ) public {
  //   vm.startPrank(owner);
  //   vm.assume(percentageFee > 0 && percentageFee <= 1000);
  //   vm.assume(treasury != address(0));

  //   uint256 totalFee = 1 ether;
  //   bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");
  //   settings.registerFunctionFees(functionBytes, 0, percentageFee, address(0), treasury);
  //   (uint256 _flatFee, uint256 _percentageFee, address tokenAddress, address _treasury, bool _isRegistered) = settings.functionFees(functionBytes);
  //   assertEq(_flatFee, 0);
  //   assertEq(_percentageFee, percentageFee);
  //   assertEq(tokenAddress, address(0));
  //   assertEq(_treasury, treasury);
  //   assertEq(_isRegistered, true);

  //   console.log("treasury fee... before...", treasury.balance);
  //   address user = userFactory.createUser{value: totalFee}();
  //   console.log("treasury.balance", treasury.balance);
  //   uint256 expectedFee = (totalFee * percentageFee) / 1000;
  //   console.log("expectedFee", expectedFee);
  //   assertEq(treasury.balance, expectedFee);
  //   assertEq(user, registry.addressToUserContracts(owner));
  //   vm.stopPrank();
  // }
}
