// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {console} from "forge-std/console.sol";
import "../contracts/Registry.sol";
import "../contracts/RegistryV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract RegistryTest is Test {
    address owner = makeAddr("owner");
    Registry public impl;
    ERC1967Proxy public proxy;
    Registry public registry;

    function setUp() public {
        vm.startPrank(owner);
        impl = new Registry();
        proxy = new ERC1967Proxy(address(impl), "");
        registry = Registry(address(proxy));
        registry.initialize("1.0");
        vm.stopPrank();
    }

    function test_addTrustedUpdater() public {
        vm.prank(owner);
        registry.addTrustedUpdater(address(0x123));
        assertEq(registry.isTrustedUpdater(address(0x123)), true);
    }

    function test_removeTrustedUpdater() public {
        vm.prank(owner);
        registry.addTrustedUpdater(address(0x123));
        vm.prank(owner);
        registry.removeTrustedUpdater(address(0x123));
        assertEq(registry.isTrustedUpdater(address(0x123)), false);
    }

    function test_setUserContract() public {
        vm.prank(owner);
        registry.setUserContract(address(0x123), address(0x456));
        assertEq(registry.addressToUserContracts(address(0x123)), address(0x456));
    }

    function test_setUserContract_invalidUser() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AddressCantBeZero.selector));
        registry.setUserContract(address(0), address(0x456));
    }
}
