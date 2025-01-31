// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/IdentityRegistry.sol";

import "../contracts/identity-resolvers/VerifyIfTrue.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract IdentityRegistryTest is Test {
    address owner = makeAddr("owner");
    IdentityRegistry public impl;
    ERC1967Proxy public proxy;
    IdentityRegistry public registry;

    function setUp() public {
        vm.startPrank(owner);
        impl = new IdentityRegistry();
        proxy = new ERC1967Proxy(address(impl), "");
        registry = IdentityRegistry(address(proxy));
        registry.initialize();
        vm.stopPrank();
    }

    function test_setResolver() public {
        vm.prank(owner);
        address resolver = address(0x123);
        registry.setResolver("test", resolver);
        assertEq(registry.identityTagToResolver("test"), resolver);
        assertEq(registry.resolverExists(resolver), true);
    }

    function test_withActiveResolver() public {
        address resolver = address(new VerifyIfTrue());
        VerifyIfTrue.VerificationData memory verificationData = VerifyIfTrue.VerificationData({ shouldVerify: true });
        bytes memory data = abi.encode(verificationData);
        vm.prank(owner);
        registry.setResolver("activeIfTrue", resolver);
        assertEq(registry.identityTagToResolver("activeIfTrue"), resolver);
        assertEq(registry.resolverExists(resolver), true);
        assertEq(IIdentityResolver(registry.identityTagToResolver("activeIfTrue")).verify(data), true);
    }
}
