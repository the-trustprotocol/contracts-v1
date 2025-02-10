// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { TestnetProcedures } from "@aave-v3-origin/tests/utils/TestnetProcedures.sol";

import "../contracts/factories/UserFactory.sol";

import "../contracts/settings/UserFactorySettings.sol";
import "../contracts/settings/UserSettings.sol";
import "../contracts/IdentityRegistry.sol";
import "../contracts/Registry.sol";
import "../contracts/interfaces/IFeeSettings.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { BondFactory } from "../contracts/factories/BondFactory.sol";
import { IBond } from "../contracts/interfaces/IBond.sol";
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

    function setUp() public {
        initTestEnvironment();
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
        vm.stopPrank();

        vm.prank(alice);
        aliceUser = User(userFactory.createUser());

        vm.prank(bob);
        bobUser = User(userFactory.createUser());

        token = tokenList.usdx;
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
}
