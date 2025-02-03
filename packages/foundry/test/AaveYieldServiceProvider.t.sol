//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {TestnetProcedures} from "@aave-v3-origin/tests/utils/TestnetProcedures.sol";
import { YieldProviderService } from "../contracts/YieldProviderService.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";
import {IAToken} from "@aave-v3-origin/src/contracts/interfaces/IAToken.sol";
contract AaveYieldServiceProvider is TestnetProcedures {
    address internal aUSDX;
    address owner = makeAddr("owner");
    address internal aavePoolAddress;
    YieldProviderService public impl;
    ERC1967Proxy public proxy;
    YieldProviderService public yieldProviderService;

    function setUp() public {
        initTestEnvironment();
        (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
        aavePoolAddress = address(contracts.poolProxy);
        impl = new YieldProviderService();
        vm.prank(owner);
        proxy = new ERC1967Proxy(address(impl), abi.encodeCall(YieldProviderService.initialize, (aavePoolAddress, aUSDX)));
        yieldProviderService = YieldProviderService(address(proxy));
    }
    function test_stake() public {

        uint256 supplyAmount = 100000000000;
        uint256 underlyingBalanceBefore = IERC20(tokenList.usdx).balanceOf(alice);
        console.log("underlyingBalanceBefore", underlyingBalanceBefore);
        vm.prank(alice);
        IERC20(tokenList.usdx).approve(address(yieldProviderService), supplyAmount);
        yieldProviderService.stake(tokenList.usdx, alice, supplyAmount);
        assertEq(IERC20(tokenList.usdx).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
        assertEq(IAToken(aUSDX).scaledBalanceOf(alice), supplyAmount);
        
        // yieldProviderService.stake(aUSDX, owner, 100);
    }
}