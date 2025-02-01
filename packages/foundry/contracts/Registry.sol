// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";

contract Registry is IRegistry, Ownable2StepUpgradeable, UUPSUpgradeable {
    mapping(address => address) public addressToUserContracts;

    //only constant or immutable variables should be in cap case
    string public VERSION;

    address[] public trustedUpdaters;

    mapping(address => bool) public isTrustedUpdater;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory version) public initializer {
        VERSION = version;
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

    // private function seems more gas optimized than modifier, we should change it to the private function
    modifier onlyTrustedUpdaterOrOwner() {
        if (!(isTrustedUpdater[msg.sender] || msg.sender == owner())) revert NotATrustedUpdaterOrOwner();
        _;
    }

    function addTrustedUpdater(address updater) external onlyOwner {
        if (updater == address(0)) revert AddressCantBeZero();
        if (isTrustedUpdater[updater]) revert UpdaterAlreadyExists();

        trustedUpdaters.push(updater);
        isTrustedUpdater[updater] = true;

        emit UpdaterAdded(updater);
    }

    function removeTrustedUpdater(address updater) external onlyOwner {
        if (!isTrustedUpdater[updater]) revert UpdaterDoesNotExist();

        isTrustedUpdater[updater] = false;

        // Remove from array
        for (uint256 i = 0; i < trustedUpdaters.length; i++) {
            if (trustedUpdaters[i] == updater) {
                trustedUpdaters[i] = trustedUpdaters[trustedUpdaters.length - 1];
                trustedUpdaters.pop();
                break;
            }
        }

        emit UpdaterRemoved(updater);
    }

    function setUserContract(address user, address contractAddress) external onlyTrustedUpdaterOrOwner {
        if (user == address(0)) revert AddressCantBeZero();
        if (contractAddress == address(0)) revert AddressCantBeZero();
        addressToUserContracts[user] = contractAddress;
        emit UserContractUpdated(user, contractAddress);
    }
}
