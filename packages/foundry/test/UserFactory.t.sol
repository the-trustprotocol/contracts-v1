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
}
