// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { FeeSettings } from "./FeeSettings.sol";

contract UserFactorySettings is FeeSettings, Ownable2StepUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    function registerFunctionFees(
        bytes4 functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress,
        address treasury
    ) external onlyOwner {
        _registerFunctionFees(functionSelector, flatFee, percentageFee, tokenAddress, treasury);
    }

    function deregisterFunctionFees(bytes4 functionSelector) external onlyOwner {
        _deregisterFunctionFees(functionSelector);
    }
}
