//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IPool } from "@aave-v3-origin/src/contracts/interfaces/IPool.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IAToken } from "@aave-v3-origin/src/contracts/interfaces/IAToken.sol";

contract YieldProviderService is
    IYieldProviderService,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable
{
    IPool public pool;
    address private _depositToken;
    address private _yieldToken;

    constructor() {
        _disableInitializers();
    }

    function initialize(address poolAddress, address yieldBearingToken, address token) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        pool = IPool(poolAddress);
        _yieldToken = yieldBearingToken;
        _depositToken = token;
    }

    function withdraw(address _user, uint256 _amount, address _to) external override nonReentrant {
        IERC20(_yieldToken).transferFrom(_user, address(this), _amount);
        IERC20(_yieldToken).approve(address(pool), _amount);
        pool.withdraw(_depositToken, _amount, _to);
    }

    function stake(address _user, uint256 _amount) external override nonReentrant {
        IERC20(_depositToken).transferFrom(_user, address(this), _amount);
        IERC20(_depositToken).approve(address(pool), _amount);
        pool.supply(_depositToken, _amount, _user, 0);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function depositToken() external view override returns (address) {
        return _depositToken;
    }

    function balanceOfToken(address addr) external view override returns (uint256) {
        IAToken(_yieldToken).balanceOf(addr);
    }

    function yieldToken() external view override returns (address) {
        return _yieldToken;
    }
}
