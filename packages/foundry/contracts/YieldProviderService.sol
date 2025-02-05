//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IPool } from "@aave-v3-origin/src/contracts/interfaces/IPool.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract YieldProviderService is
    IYieldProviderService,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable
{
    IPool public pool;
    address public yToken;

    constructor() {
        _disableInitializers();
    }

    function initialize(address poolAddress, address yieldBearingToken) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        pool = IPool(poolAddress);
        yToken = yToken;
    }

    function withdraw(address _assetAddress, address _user, uint256 _amount) external override nonReentrant {
        pool.withdraw(_assetAddress, _amount, _user);
    }

    function stake(address _assetAddress, address _user, uint256 _amount) external override nonReentrant {
        IERC20(_assetAddress).transferFrom(_user, address(this), _amount);
        IERC20(_assetAddress).approve(address(pool), _amount);
        pool.supply(_assetAddress, _amount, _user, 0);
    }  
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
