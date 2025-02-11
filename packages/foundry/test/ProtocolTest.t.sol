// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { TestnetProcedures } from "@aave-v3-origin/tests/utils/TestnetProcedures.sol";

import "../contracts/factories/UserFactory.sol";

import { console } from "forge-std/console.sol";

import "../contracts/settings/UserFactorySettings.sol";
import "../contracts/settings/UserSettings.sol";
import "../contracts/IdentityRegistry.sol";
import "../contracts/Registry.sol";
import "../contracts/interfaces/IFeeSettings.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { BondFactory } from "../contracts/factories/BondFactory.sol";
import { IBond } from "../contracts/interfaces/IBond.sol";

import { Bond } from "../contracts/Bond.sol";
import { YieldProviderService } from "../contracts/YieldProviderService.sol";

contract ProtocolTest is TestnetProcedures {
    address owner = makeAddr("owner");
    address treasury = makeAddr("treasury");
    UserFactory public userFactoryImpl;
    ERC1967Proxy public userFactoryProxy;
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

    BondFactory public bondFactoryImpl;
    ERC1967Proxy public bondFactoryProxy;
    BondFactory public bondFactory;

    YieldProviderService public yieldProviderServiceImpl;
    ERC1967Proxy public yieldProviderProxy;
    YieldProviderService public yieldProviderService;

    User public aliceUser;
    User public bobUser;

    address public token;
    address internal aUSDX;

    function setUp() public {
        initTestEnvironment();
        vm.startPrank(owner);
        (aUSDX,,) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
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

        bondFactory = new BondFactory();
        bondFactoryProxy = new ERC1967Proxy(address(bondFactory), abi.encodeCall(BondFactory.initialize, ()));
        bondFactory = BondFactory(address(bondFactoryProxy));

        userFactoryImpl = new UserFactory();
        userFactoryProxy = new ERC1967Proxy(
            address(userFactoryImpl),
            abi.encodeCall(
                UserFactory.initialize,
                (address(settings), address(registry), address(userSettings), address(identityRegistry))
            )
        );
        userFactory = UserFactory(address(userFactoryProxy));
        registry.addTrustedUpdater(address(userFactory));

        yieldProviderServiceImpl = new YieldProviderService();
        yieldProviderProxy = new ERC1967Proxy(
            address(yieldProviderServiceImpl),
            abi.encodeCall(YieldProviderService.initialize, (address(contracts.poolProxy), aUSDX, tokenList.usdx))
        );
        yieldProviderService = YieldProviderService(address(yieldProviderProxy));

        vm.stopPrank();
        token = tokenList.usdx;
    }

    function test_create2UsersWithInitial() public {
        vm.startPrank(alice);
        uint256 initialStake = IERC20(token).balanceOf(alice);
        console.log("initialStake", initialStake);
        IERC20(token).approve(address(userFactory), initialStake);
        userFactory.createUserWithBond(alice, bob, initialStake, address(bondFactory), address(yieldProviderService));
        vm.stopPrank();
        aliceUser = User(registry.addressToUserContracts(alice));
        bobUser = User(registry.addressToUserContracts(bob));

        assertEq(aliceUser.owner(), alice);
        assertEq(bobUser.owner(), bob);
        assertEq(aliceUser.getAllBonds().length, 1);
        Bond bond = Bond(aliceUser.getAllBonds()[0]);
        assertEq(bond.individualPercentage(address(aliceUser)), 10000);
        assertEq(bond.individualAmount(address(aliceUser)), initialStake);
    }

    function test_createBond() public {
        vm.startPrank(alice);
        uint256 initialStake = IERC20(token).balanceOf(alice);
        console.log("initialStake", initialStake);
        userFactory.createUserWithBond(alice, bob, 0, address(bondFactory), address(yieldProviderService));
        aliceUser = User(registry.addressToUserContracts(alice));
        bobUser = User(registry.addressToUserContracts(bob));
        console.log("initialStake", initialStake);

        IERC20(token).approve(address(aliceUser), initialStake);
        aliceUser.createBond(bob, token, address(yieldProviderService), initialStake, address(bondFactory));

        assertEq(aliceUser.owner(), alice);
        assertEq(bobUser.owner(), bob);
        assertEq(aliceUser.getAllBonds().length, 1);
        assertEq(bobUser.getAllBonds().length, 1);
        Bond bond = Bond(aliceUser.getAllBonds()[0]);
        assertEq(bond.individualPercentage(address(aliceUser)), 10000);
        assertEq(bond.individualAmount(address(aliceUser)), initialStake);
        vm.stopPrank();
    }

    function test_withdrawBond() public {
        vm.startPrank(alice);
        uint256 initialStake = IERC20(token).balanceOf(alice);
        console.log("initialStake", initialStake);
        IERC20(token).approve(address(userFactory), initialStake);
        userFactory.createUserWithBond(alice, bob, initialStake, address(bondFactory), address(yieldProviderService));
        aliceUser = User(registry.addressToUserContracts(alice));
        Bond bond = Bond(aliceUser.getAllBonds()[0]);
        aliceUser.withdraw(address(bond));
        assertEq(IERC20(token).balanceOf(alice), initialStake);
        assertEq(bond.individualAmount(address(aliceUser)), 0);
        vm.stopPrank();
    }

    function test_breakBond() public {
        vm.startPrank(alice);
        uint256 initialStake = IERC20(token).balanceOf(alice);
        uint256 initialBalanceOfBob = IERC20(token).balanceOf(bob);
        IERC20(token).approve(address(userFactory), initialStake);
        userFactory.createUserWithBond(alice, bob, initialStake, address(bondFactory), address(yieldProviderService));
        aliceUser = User(registry.addressToUserContracts(alice));
        bobUser = User(registry.addressToUserContracts(bob));

        console.log("Bog user", address(bobUser));
        console.log("Bog user again", userFactory.createUser(bob));
        vm.stopPrank();
        vm.startPrank(bob);
        bobUser = User(registry.addressToUserContracts(bob));

        Bond bond = Bond(aliceUser.getAllBonds()[0]);

        bobUser.breakBond(address(bond));
        assertGe(IERC20(token).balanceOf(bob), initialBalanceOfBob);
        assertEq(bond.individualAmount(address(aliceUser)), 0);
        vm.stopPrank();
    }
}
