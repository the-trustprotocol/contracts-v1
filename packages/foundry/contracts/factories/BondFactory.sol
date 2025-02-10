// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Bond } from "../Bond.sol";
import { IBondFactory } from "../interfaces/IBondFactory.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BondFactory is IBondFactory, Ownable2StepUpgradeable, UUPSUpgradeable {
    using Clones for address;

    // address public implementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function createBond(address _asset, address _user1, address _user2, address _yieldProviderServiceAddress)
        external
        override
        returns (address)
    {
        Bond bond = new Bond(_asset, _user1, _user2, _yieldProviderServiceAddress);
        return address(bond);
    }

    // function updateImplementation(address _newImplementation) external onlyOwner {
    //     implementation = _newImplementation;
    // }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
