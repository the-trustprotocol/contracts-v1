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

    address internal aUSDX;
    address internal aWBTC;

    BondFactory public bondFactory;
    uint256 stakeAmount = 100_000e6; 
    ERC1967Proxy public bondProxy;
    ERC1967Proxy public ypsProxy;
    ERC1967Proxy public ypsFactoryProxy;
    YieldProviderService public yps;
    PoolAddressesProvider public poolAddressProvider;


    function setUp() public { 
        initTestEnvironment();

        (aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
        (aWBTC, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.wbtc);
  
        bond = new Bond();
        
        bondProxy = new ERC1967Proxy(address(bond), "");
        bond = Bond(address(bondProxy));

        yps = new YieldProviderService();
        ypsProxy = new ERC1967Proxy(address(yps), "");
        yps = YieldProviderService(address(ypsProxy));
        yps.initialize(address(contracts.poolProxy), address(aUSDX));
        vm.prank(alice);
        assertEq(IERC20(tokenList.usdx).balanceOf(alice), 100_000e6);
        vm.prank(alice);
        IERC20(tokenList.usdx).approve(address(bond), stakeAmount);
        vm.prank(alice);
        bond.initialize(tokenList.usdx, alice, bob, stakeAmount, address(yps));
    }

    function test_initialization() public view {
        assertEq(bond.owner(), alice);
        (, address _user1, address _user2, uint256 _totalBondAmount, , bool _isBroken, bool _isWithdrawn, bool _isActive, bool _isFreezed) = bond.bond();
        assertEq(_user1, alice);
        assertEq(_user2, bob);
        assertEq(_totalBondAmount, stakeAmount);
        assertEq(_isBroken, false);
        assertEq(_isWithdrawn, false);
        assertEq(_isActive, true);
        assertEq(_isFreezed, false);
        assertEq(bond.individualAmount(alice), stakeAmount);
        assertEq(bond.individualPercentage(alice), 100);
        assertEq(bond.isUser(alice), true);
        assertEq(bond.isUser(bob), true);
        assertEq(bond.individualAmount(bob), 0);
        assertEq(bond.individualPercentage(bob), 0);
    }

    function testFuzz_stake(uint256 _stakeAmount) public {
        vm.assume(_stakeAmount >= 100e6 && _stakeAmount <= 1000e6);
        vm.prank(bob);
        IERC20(tokenList.usdx).approve(address(bond), _stakeAmount);
        console.log("Allowance bob-yps:", IERC20(tokenList.usdx).allowance(bob, address(bond)));
        vm.prank(bob);
        bond.stake(tokenList.usdx, bob, _stakeAmount);
        (, , , uint256 _totalBondAmount, , , , , ) = bond.bond();
        console.log("a token balance:", IERC20(aUSDX).balanceOf(address(bond)));
        console.log("total bond amount:", _totalBondAmount);
        assertEq(bond.individualAmount(bob), _stakeAmount);
        // assertEq(bond.individualPercentage(bob), 0);
        assert(_totalBondAmount <= IERC20(aUSDX).balanceOf(address(bond)));
    }

    function testFuzz_withdraw(uint256 _stakeAmount) public {
        testFuzz_stake(_stakeAmount);

        vm.warp(block.timestamp + 100000 days); //somehow its not increasing yield

        uint256 individualAmount = bond.individualAmount(bob);
        uint256 balanceBefore = IERC20(tokenList.usdx).balanceOf(bob);

        (, , ,uint256 _totalBondAmount , , , , , ) = bond.bond();
        console.log(IERC20(aUSDX).balanceOf(address(bond)) - _totalBondAmount);

        uint256 balanceInBondBefore = IERC20(aUSDX).balanceOf(address(bond));

        vm.prank(bob);
        bond.withdrawBond(tokenList.usdx, bob, aUSDX);

        (, , , , , bool _isBroken, bool _isWithdrawn, bool _isActive, bool _isFreezed) = bond.bond();
        assert(balanceBefore + individualAmount <= IERC20(tokenList.usdx).balanceOf(bob));
        assert(bond.individualAmount(bob) == 0);
        assertFalse(balanceInBondBefore == IERC20(aUSDX).balanceOf(address(bond)));
        assert(balanceInBondBefore > IERC20(aUSDX).balanceOf(address(bond)));
        assertTrue(_isWithdrawn);
    }

    function testFuzz_breakBond(uint256 _stakeAmount) public {
        testFuzz_stake(_stakeAmount);

        vm.warp(block.timestamp + 100000 days); //somehow its not increasing yield

        uint256 balanceBefore = IERC20(tokenList.usdx).balanceOf(bob);

        (, , ,uint256 _totalBondAmount , , , , , ) = bond.bond();
        console.log(IERC20(aUSDX).balanceOf(address(bond)) - _totalBondAmount);

        uint256 balanceInBondBefore = IERC20(aUSDX).balanceOf(address(bond));

        vm.prank(bob);
        bond.breakBond(tokenList.usdx, bob, aUSDX);

        (, , , , , bool _isBroken, bool _isWithdrawn, bool _isActive, bool _isFreezed) = bond.bond();
        assert(balanceBefore + _totalBondAmount <= IERC20(tokenList.usdx).balanceOf(bob));
        assert(bond.individualAmount(bob) == 0);
        assert(bond.individualAmount(alice) == 0);
        assertFalse(balanceInBondBefore == IERC20(aUSDX).balanceOf(address(bond)));
        assert(balanceInBondBefore > IERC20(aUSDX).balanceOf(address(bond)));
        assertTrue(_isBroken);
        assertFalse(_isActive);
    }
}