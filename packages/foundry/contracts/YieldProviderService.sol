//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IPool } from "@aave/interfaces/IPool.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract YieldProviderService is
    IYieldProviderService,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable
{
    IPool public aavePool;

    constructor() {
        _disableInitializers();
    }

    function initialize(address poolAddress) external initializer {
        __Ownable_init(msg.sender); // msg.sender is the bond contract, so bond contract will be the owner
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        aavePool = IPool(poolAddress);
    }

    function withdrawBond(address _assetAddress, address _user, uint256 _amount) external override nonReentrant {
        aavePool.withdraw(_assetAddress, _amount, _user);
    }

    function stake(address _assetAddress, address _user, uint256 _amount) external override nonReentrant {
        aavePool.supply(_assetAddress, _amount, _user, 0);
    }
    

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
