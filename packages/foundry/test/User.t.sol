//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {console} from "forge-std/console.sol";
import { IFeeSettings } from "../contracts/interfaces/IFeeSettings.sol";
import { IIdentityRegistry } from "../contracts/interfaces/IIdentityRegistry.sol";

import {FeeSettings} from "../contracts/settings/FeeSettings.sol";
import {IdentityRegistry} from "../contracts/IdentityRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {User} from "../contracts/User.sol";

import {BondFactory} from "../contracts/factories/BondFactory.sol";
import {YieldProviderService} from "../contracts/YieldProviderService.sol";
import {Bond} from "../contracts/Bond.sol";
import {IBond} from "../contracts/interfaces/IBond.sol";

import {AaveYieldServiceProvider} from "./AaveYieldServiceProvider.t.sol";
import {TestnetProcedures} from "@aave-v3-origin/tests/utils/TestnetProcedures.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UserTest is TestnetProcedures {

    IdentityRegistry public identityRegistryImpl;
    ERC1967Proxy public identityRegistryProxy;

    FeeSettings public feeSettingsImpl;

    User public userImpl;
    ERC1967Proxy public userProxy;
    User public user;

    BondFactory public bondFactoryImpl;
    ERC1967Proxy public bondFactoryProxy;

    Bond public bondImpl;

    AaveYieldServiceProvider public aaveYieldServiceProvider;

    address public owner;
    address public bondAddress;

    address internal aUSDX;
    address internal aWBTC;

    function setUp() public {

        initTestEnvironment();

        (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
        (aWBTC, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);

        aaveYieldServiceProvider = new AaveYieldServiceProvider();
        aaveYieldServiceProvider.setUp();

        owner = aaveYieldServiceProvider.owner();

        vm.startPrank(owner);

        identityRegistryImpl = new IdentityRegistry();
        identityRegistryProxy = new ERC1967Proxy(address(identityRegistryImpl), "");
        identityRegistryImpl = IdentityRegistry(address(identityRegistryProxy));
        identityRegistryImpl.initialize();

        feeSettingsImpl = new FeeSettings();

        bondImpl = new Bond();

        bondFactoryImpl = new BondFactory();
        bondFactoryProxy = new ERC1967Proxy(address(bondFactoryImpl), "");
        bondFactoryImpl = BondFactory(address(bondFactoryProxy));
        bondFactoryImpl.initialize(address(bondImpl));


        console.log("bondFactoryImpl", address(bondFactoryImpl));

        console.log(owner);
        console.log("this address", address(this));
        console.log("yps address", address(aaveYieldServiceProvider));
        userImpl = new User(address(identityRegistryImpl), address(feeSettingsImpl));
        // userProxy = new ERC1967Proxy(address(userImpl), "");
        // user = User(address(userProxy));

        vm.stopPrank();

    }

    function test_createBond() public {

        vm.startPrank(owner);
        YieldProviderService ypsAddress = aaveYieldServiceProvider.yieldProviderService();
        
        vm.startPrank(alice);
        IERC20(tokenList.usdx).approve(address(userImpl), 1000);
        IERC20(tokenList.usdx).approve(address(bondFactoryImpl), 1000);
        userImpl.createBond(
                IBond.BondDetails({
                    asset: tokenList.usdx,
                    user1: alice,
                    user2: bob,
                    totalBondAmount: 1000,
                    createdAt: block.timestamp,
                    isBroken: false,
                    isWithdrawn: false,
                    isActive: true,
                    isFreezed: false            
                }),
                address(bondFactoryImpl),
                address(ypsAddress)
        );
        // bondAddress = address(userImpl.createBond(
        //         IBond.BondDetails({
        //             asset: address(0),
        //             user1: address(0),
        //             user2: address(0),
        //             totalBondAmount: 0,
        //             createdAt: block.timestamp,
        //             isBroken: false,
        //             isWithdrawn: false,
        //             isActive: true,
        //             isFreezed: false            
        //         }),
        //         address(bondFactoryImpl),
        //         address(ypsAddress)
        //     ));

        vm.stopPrank();
    }

    // function test_getBond() public {
    //     user.getBondDetails(bondAddress);
    // }
}