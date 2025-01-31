// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/factories/UserFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract UserFactoryTest is Test {
  address owner = makeAddr("owner");
  UserFactory public impl;
  ERC1967Proxy public proxy;
  UserFactory public userFactory;

  function testProxyDeployment() public {
    vm.prank(owner);
    impl = new UserFactory();
    proxy = new ERC1967Proxy(address(impl), "");
    address mockSettings = address(0x123);
    address mockRegistry = address(0x456);
    bytes memory initData = abi.encodeCall(UserFactory.initialize, (mockSettings, mockRegistry));
    proxy = new ERC1967Proxy(address(impl), initData);
    userFactory = UserFactory(address(proxy));
    console.log("userFactory address: ", address(userFactory));
    assertEq(address(userFactory.settings()), mockSettings);
    assertEq(address(userFactory.registry()), mockRegistry);
    assertNotEq(address(userFactory),address(0));
  }
}