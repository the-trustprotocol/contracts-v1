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
        settingsProxy = new ERC1967Proxy(address(settingsImpl), "");
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
            abi.encodeCall(
                UserFactory.initialize,
                (address(settings), address(registry), address(userSettings), address(identityRegistry))
            )
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

    function test_createUserWithFlatFees() public {
        vm.startPrank(owner);
        vm.deal(owner, 2 ether);
        bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");
        settings.registerFunctionFees(functionBytes, 1 ether, 0, address(0), treasury);
        address user = userFactory.createUser{ value: 2 ether }();
        assertEq(user, registry.addressToUserContracts(owner));
        assertEq(treasury.balance, 1 ether);
        assertEq(owner.balance, 1 ether);
        vm.stopPrank();
    }

    function test_createUserWithPercentageFees() public {
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);
        uint256 percentage = 100;
        uint256 totalFee = 1 ether;
        bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");
        settings.registerFunctionFees(functionBytes, 0, percentage, address(0), treasury);
        uint256 expectedFee = (totalFee * percentage) / 1000;
        address user = userFactory.createUser{ value: totalFee }();
        assertEq(user, registry.addressToUserContracts(owner));
        console.log("treasury.balance", treasury.balance);
        console.log("expectedFee", expectedFee);
        console.log("owner.balance", owner.balance);
        assertEq(treasury.balance, expectedFee);
        assertEq(owner.balance, totalFee - expectedFee);
        vm.stopPrank();
    }

    function test_createUserWithTokenFees() public {
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);
        uint256 percentage = 100;
        uint256 feeSent = 1 ether;
        uint256 totalFee = 0.5 ether;
        bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUser()");
        settings.registerFunctionFees(functionBytes, totalFee, percentage, address(0), treasury);
        address user = userFactory.createUser{ value: feeSent }();
        assertEq(user, registry.addressToUserContracts(owner));
        uint256 expectedFee = ((feeSent * percentage) / 1000) + totalFee;
        assertEq(treasury.balance, expectedFee);
        assertEq(owner.balance, feeSent - expectedFee);
        vm.stopPrank();
    }

    function test_createGaslessUserWithTokenFees() public {
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);
        uint256 percentage = 100;
        uint256 feeSent = 1 ether;
        uint256 totalFee = 0.5 ether;
        bytes4 functionBytes = IFeeSettings(address(settings)).getFunctionSelector("createUserOnBehalf(address)");
        settings.registerFunctionFees(functionBytes, totalFee, percentage, address(0), treasury);
        vm.stopPrank();
        address gasFeePayer = makeAddr("gasFeePayer");

        vm.startPrank(gasFeePayer);
        vm.deal(gasFeePayer, feeSent);
        console.log("gasFeePayer.balance", gasFeePayer.balance);
        address user = userFactory.createUserOnBehalf{ value: feeSent }(owner);
        console.log("gasFeePayer.balance 2", gasFeePayer.balance);
        assertEq(user, registry.addressToUserContracts(owner));
        uint256 expectedFee = ((feeSent * percentage) / 1000) + totalFee;
        assertEq(treasury.balance, expectedFee);
        assertEq(gasFeePayer.balance, feeSent - expectedFee);
        vm.stopPrank();
    }
}
