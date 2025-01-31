// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../contracts/factories/UserFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract UserFactoryTest is Test {
  address owner = makeAddr("owner");
  UserFactory public impl;
  ERC1967Proxy public proxy;
  UserFactory public userFactory;

  function setUp() public {
    impl = new UserFactory();
    proxy = new ERC1967Proxy(address(impl), "");
    userFactory = UserFactory(address(proxy));
  }
  
}