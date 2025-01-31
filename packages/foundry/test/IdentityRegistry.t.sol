// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/IdentityRegistry.sol";
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
}