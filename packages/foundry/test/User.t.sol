//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";

import { console } from "forge-std/console.sol";
import { IFeeSettings } from "../contracts/interfaces/IFeeSettings.sol";
import { IIdentityRegistry } from "../contracts/interfaces/IIdentityRegistry.sol";

import { FeeSettings } from "../contracts/settings/FeeSettings.sol";
import { IdentityRegistry } from "../contracts/IdentityRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { User } from "../contracts/User.sol";

import { BondFactory } from "../contracts/factories/BondFactory.sol";
import { YieldProviderService } from "../contracts/YieldProviderService.sol";
import { Bond } from "../contracts/Bond.sol";
import { IBond } from "../contracts/interfaces/IBond.sol";

import { AaveYieldServiceProvider } from "./AaveYieldServiceProvider.t.sol";
import { TestnetProcedures } from "@aave-v3-origin/tests/utils/TestnetProcedures.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { VerifyIfTrue } from "../contracts/identity-resolvers/VerifyIfTrue.sol";

contract UserTest is TestnetProcedures {
    IdentityRegistry public identityRegistryImpl;
    ERC1967Proxy public identityRegistryProxy;

    FeeSettings public feeSettingsImpl;

    User public userImpl;
    ERC1967Proxy public userProxy;
    User public user;

    BondFactory public bondFactoryImpl;
    ERC1967Proxy public bondFactoryProxy;

    AaveYieldServiceProvider public aaveYieldServiceProvider;

    address public owner;
    address public bondAddress;

    address internal aUSDX;
    address internal aWBTC;

    function setUp() public {
        initTestEnvironment();

        (aUSDX,,) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
        (aWBTC,,) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);

        aaveYieldServiceProvider = new AaveYieldServiceProvider();
        aaveYieldServiceProvider.setUp();

        owner = aaveYieldServiceProvider.owner();

        vm.startPrank(owner);

        identityRegistryImpl = new IdentityRegistry();
        identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), "");
        identityRegistryImpl = IdentityRegistry(address(identityRegistryProxy));
        identityRegistryImpl.initialize();

        feeSettingsImpl = new FeeSettings();

        bondFactoryImpl = new BondFactory();
        bondFactoryProxy = new ERC1967Proxy(address(bondFactoryImpl), "");
        bondFactoryImpl = BondFactory(address(bondFactoryProxy));
        bondFactoryImpl.initialize();

        console.log("bondFactoryImpl", address(bondFactoryImpl));

        console.log(owner);
        console.log("this address", address(this));
        console.log("yps address", address(aaveYieldServiceProvider));
        userImpl = new User(owner,address(identityRegistryImpl), address(feeSettingsImpl),address(0));

        vm.stopPrank();
    }

  
    function test_verifyIdentity() public {
        vm.startPrank(owner);
        console.log("address", address(new VerifyIfTrue()));
        address resolver = address(new VerifyIfTrue());
        console.log("resolver", resolver);
        VerifyIfTrue.VerificationData memory verificationData = VerifyIfTrue.VerificationData({ shouldVerify: true });
        bytes memory data = abi.encode(verificationData);
        console.logBytes(data);
        identityRegistryImpl.setResolver("activeIfTrue", resolver);
        assertEq(resolver, identityRegistryImpl.getResolver("activeIfTrue"), "Resolver not set");
        bool verified = userImpl.verifyIdentity("activeIfTrue", data);
        assertTrue(verified, "Identity not verified");
        vm.stopPrank();
    }
}
