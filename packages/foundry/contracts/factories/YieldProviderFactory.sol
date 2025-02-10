// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { YieldProviderService } from "../YieldProviderService.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IYieldProviderServiceFactory } from "../interfaces/IYieldProviderServiceFactory.sol";

contract YieldProviderFactory is IYieldProviderServiceFactory, Ownable2StepUpgradeable, UUPSUpgradeable {
    using Clones for address;

    address public implementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _bondImplementation) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        implementation = _bondImplementation;
    }

    function createYPS(address _aavePoolAddress, address _aToken, address _token) external override returns (address) {
        address newYPS = implementation.clone();

        YieldProviderService(newYPS).initialize(_aavePoolAddress, _aToken, _token);
        return newYPS;
    }

    function updateImplementation(address _newImplementation) external onlyOwner {
        implementation = _newImplementation;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
