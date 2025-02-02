//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import { Bond } from "../contracts/Bond.sol";
import { YieldProviderService } from "../contracts/YieldProviderService.sol";
import { BondFactory } from "../contracts/factories/BondFactory.sol";
import { MockPoolInherited } from "@aave-v3-origin/src/contracts/mocks/helpers/MockPool.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {PoolAddressesProvider} from "@aave-v3-origin/src/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {IPoolAddressesProvider} from "@aave-v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {TestnetProcedures} from "@aave-v3-origin/tests/utils/TestnetProcedures.sol";

import {IAToken} from "@aave-v3-origin/src/contracts/interfaces/IAToken.sol";

contract BondTest is TestnetProcedures {
    Bond public bond;
    // IPool internal pool;

    address internal aUSDX;
    address internal aWBTC;

    BondFactory public bondFactory;
    ERC1967Proxy public bondProxy;
    ERC1967Proxy public ypsProxy;
    ERC1967Proxy public ypsFactoryProxy;
    YieldProviderService public yps;
    // MockPoolInherited public pool;
    PoolAddressesProvider public poolAddressProvider;

    string public marketId;

    // address public owner = makeAddr("owner address");
    // address public user1 = makeAddr("user1 address");
    // address public user2 = makeAddr("user2 address");

    // uint256 public user1Initial;

    // ERC20Mock public token;
    // ERC20Mock public aToken;

    function setUp() public {
        // vm.startPrank(owner);
        // vm.deal(owner, 1 ether);
        initTestEnvironment();

        (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
        (aWBTC, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);
  

        // token = new ERC20Mock();
        // token.mint(owner, 1_000_000_000_000 * 1e18);
        // aToken = new ERC20Mock();
        // aToken.mint(owner, 1_000_000_000 * 1e18);
        // marketId = "firstone";

        // poolAddressProvider = new PoolAddressesProvider(marketId, owner);
        // pool = new MockPoolInherited(IPoolAddressesProvider(poolAddressProvider));
        // pool.initialize(IPoolAddressesProvider(poolAddressProvider));

        // pool.supply(address(token), 1_000 * 1e18, owner, 0);
      

        // console.log("pool address.....",address(pool));

        // user1Initial = 1_000 * 1e18;

        // bondFactory = new BondFactory();

        bond = new Bond();
        
        bondProxy = new ERC1967Proxy(address(bond), "");
        bond = Bond(address(bondProxy));

        yps = new YieldProviderService();
        ypsProxy = new ERC1967Proxy(address(yps), "");
        yps = YieldProviderService(address(ypsProxy));
        yps.initialize(address(contracts.poolProxy), address(aUSDX));
        console.log("yps address......",address(yps));
        console.log(tokenList.usdx);

  
        // token.approve(user1, 1_000_000 * 1e18);
        // token.approve(user2, 1_000_000 * 1e18);
        // token.transfer(user1, 1_000_000 * 1e18);
        vm.prank(alice);
        assertEq(IERC20(tokenList.usdx).balanceOf(alice), 100_000e6);

        // vm.prank(alice);
        // IERC20(tokenList.usdx).approve(address(yps), 1e6);
        // console.log("Allowance:", IERC20(tokenList.usdx).allowance(alice, address(yps)));

        vm.prank(alice);
        IERC20(tokenList.usdx).approve(address(bond), 1e6);
        console.log("Allowance:", IERC20(tokenList.usdx).allowance(alice, address(bond)));

        vm.prank(address(yps));
        IERC20(tokenList.usdx).approve(address(contracts.poolProxy), 1e6);


        console.log("Bond contract balance:", IERC20(tokenList.usdx).balanceOf(address(bond)));
        vm.prank(alice);
        bond.initialize(tokenList.usdx, alice, bob, 1e6, address(yps));
        console.log("allowance bond-yps", IERC20(tokenList.usdx).allowance(address(bond), address(yps)));
        console.log("Bond contract balance:", IERC20(tokenList.usdx).balanceOf(address(bond)));
        console.log("Alice balance:", IERC20(tokenList.usdx).balanceOf(alice));
        console.log("yps balance:", IERC20(tokenList.usdx).balanceOf(address(yps)));
    }

    // function test_initialization() public view {
    //     assertEq(bond.owner(), owner);
    //     (, address _user1, address _user2, uint256 _totalBondAmount, , bool _isBroken, bool _isWithdrawn, bool _isActive, bool _isFreezed) = bond.bond();
    //     assertEq(_user1, user1);
    //     assertEq(_user2, user2);
    //     assertEq(_totalBondAmount, user1Initial);
    //     assertEq(_isBroken, false);
    //     assertEq(_isWithdrawn, false);
    //     assertEq(_isActive, true);
    //     assertEq(_isFreezed, false);
    // }

    function test_firstSupply() public {
        uint256 supplyAmount = 0.2e8;
        uint256 underlyingBalanceBefore = IERC20(tokenList.wbtc).balanceOf(alice);

        // vm.expectEmit(report.poolProxy);
        // emit ReserveUsedAsCollateralEnabled(tokenList.wbtc, alice);
        // vm.expectEmit(report.poolProxy);
        // emit Supply(tokenList.wbtc, alice, alice, supplyAmount, 0);

        vm.prank(alice);
        contracts.poolProxy.supply(tokenList.wbtc, supplyAmount, alice, 0);

        assertEq(IERC20(tokenList.wbtc).balanceOf(alice), underlyingBalanceBefore - supplyAmount);
        assertEq(IAToken(aWBTC).scaledBalanceOf(alice), supplyAmount);
    }
}