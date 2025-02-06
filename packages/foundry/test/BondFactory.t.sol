//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BondFactory} from "../contracts/factories/BondFactory.sol";
import {Bond} from "../contracts/Bond.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract BondFactoryTest is Test{

    Bond public bond;

    BondFactory public bondFactory;
    ERC1967Proxy public bondFactoryProxy;

    function setUp() public {

        bondFactory = new BondFactory();
        bondFactoryProxy = new ERC1967Proxy(address(bondFactory), "");
        bondFactory = BondFactory(address(bondFactoryProxy));
        bondFactory.initialize();

    }

    function test_createBond() public {
        
    }
}