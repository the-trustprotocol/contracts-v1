// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import './interfaces/IRegistry.sol';

contract Registry is IRegistry, Ownable2StepUpgradeable, UUPSUpgradeable {
    mapping(address => address) public addressToUserContracts;

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

    modifier onlyTrustedUpdaterOrOwner() {
        require(isTrustedUpdater[msg.sender] || msg.sender == owner(), 'Not a trusted updater or owner');
        _;
    }

    function addTrustedUpdater(address updater) external onlyOwner {
        require(updater != address(0), 'Invalid address');
        require(!isTrustedUpdater[updater], 'Already trusted updater');

        trustedUpdaters.push(updater);
        isTrustedUpdater[updater] = true;

        emit UpdaterAdded(updater);
    }

    function removeTrustedUpdater(address updater) external onlyOwner {
        require(isTrustedUpdater[updater], 'Not a trusted updater');

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
        require(user != address(0), 'Invalid user address');
        require(contractAddress != address(0), 'Invalid contract address');
        addressToUserContracts[user] = contractAddress;
        emit UserContractUpdated(user, contractAddress);
    }
}
