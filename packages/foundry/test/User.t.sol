//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
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

contract UserTest is Test {

    IdentityRegistry public identityRegistryImpl;
    ERC1967Proxy public identityRegistryProxy;

    FeeSettings public feeSettingsImpl;

    User public userImpl;
    ERC1967Proxy public userProxy;
    User public user;

    BondFactory public bondFactoryImpl;
    ERC1967Proxy public bondFactoryProxy;

    YieldProviderService public yieldProviderService;

    Bond public bondImpl;

    function setUp() public {

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


        userImpl = new User(address(identityRegistryImpl), address(feeSettingsImpl));
        // userProxy = new ERC1967Proxy(address(userImpl), "");
        // user = User(address(userProxy));

    }

    function test_createBond() public {

        // userImpl.createBond(
        //     IBond.BondDetails({
        //         asset: address(0),
        //         user1: address(0),
        //         user2: address(0),
        //         totalBondAmount: 0,
        //         createdAt: block.timestamp,
        //         isBroken: false,
        //         isWithdrawn: false,
        //         isActive: true,
        //         isFreezed: false            
        //     }),
        //     address(bondFactoryImpl),
        //     address(YieldProviderService)
        // );
    }
}