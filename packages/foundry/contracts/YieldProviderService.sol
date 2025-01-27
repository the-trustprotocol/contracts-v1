//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IPool } from "@aave/interfaces/IPool.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";

contract YieldProviderService is IYieldProviderService {
    IPool public aavePool;

    constructor(address poolAddress) {
        aavePool = IPool(poolAddress);
    }

    function withdrawBond(address _assetAddress, address _user, uint256 _amount) external {
        aavePool.withdraw(_assetAddress, _amount, _user);
    }

    function freezeBond(uint256 _id) external { }

    function stake(address _assetAddress, address _user, uint256 _amount) external {
        aavePool.supply(_assetAddress, _amount, _user, 0);
    }
}
