//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import { Bond } from "../contracts/Bond.sol";
import { YieldProviderService } from "../contracts/YieldProviderService.sol";
import { BondFactory } from "../contracts/factories/BondFactory.sol";
import { YieldProviderFactory } from "../contracts/factories/YieldProviderFactory.sol";

import { MockPool } from "@aave/mocks/helpers/MockPool.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { UiPoolDataProviderV3 } from "@aave-origin/periphery/contracts/misc/UiPoolDataProviderV3.sol";
import { IEACAggregatorProxy } from "@aave-origin/periphery/contracts/misc/interfaces/IEACAggregatorProxy.sol";

contract BondTest is Test {
    Bond public bond;
    BondFactory public bondFactory;
    ERC1967Proxy public bondProxy;
    ERC1967Proxy public ypsProxy;
    ERC1967Proxy public ypsFactoryProxy;
    YieldProviderService public yps;
    MockPool public aavePool;
    UiPoolDataProviderV3 public pds;
    YieldProviderFactory public ypsFactory;

    //these 2 were used in parameters for uipooldataprovider till we find the mock ui pool data provider....
    IEACAggregatorProxy public immutable networkBaseTokenPriceInUsdProxyAggregator;
    IEACAggregatorProxy public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;

    address public owner = makeAddr("owner address");
    address public user1 = makeAddr("user1 address");
    address public user2 = makeAddr("user2 address");

    uint256 public user1Initial;

    ERC20Mock public token;
    ERC20Mock public aToken;

    function setUp() public {
        vm.startPrank(owner);

        token = new ERC20Mock();
        token.mint(owner, 1_000_000_000_000 * 1e18);
        aToken = new ERC20Mock();
        aToken.mint(owner, 1_000_000_000 * 1e18);

        user1Initial = 1_000 * 1e18;

        bondFactory = new BondFactory();
        aavePool = new MockPool();
        bond = new Bond();
        bondProxy = new ERC1967Proxy(address(bond), "");
        bond = Bond(address(bondProxy));

        yps = new YieldProviderService();
        ypsProxy = new ERC1967Proxy(address(yps), "");
        yps = YieldProviderService(address(ypsProxy));

        ypsFactory = new YieldProviderFactory();
        ypsFactoryProxy = new ERC1967Proxy(address(ypsFactory), "");
        ypsFactory = YieldProviderFactory(address(ypsFactoryProxy));
        ypsFactory.initialize(address(yps));

        pds = new UiPoolDataProviderV3(
            IEACAggregatorProxy(networkBaseTokenPriceInUsdProxyAggregator),
            IEACAggregatorProxy(marketReferenceCurrencyPriceInUsdProxyAggregator)
        );

        token.approve(user1, 1_000_000 * 1e18);
        token.approve(user2, 1_000_000 * 1e18);
        token.transfer(user1, 1_000_000 * 1e18);
        bond.initialize(
            address(token), user1, user2, user1Initial, address(aavePool), address(pds), address(ypsFactory)
        );
        vm.stopPrank();
    }
}
