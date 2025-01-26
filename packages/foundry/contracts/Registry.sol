// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Registry is Ownable2StepUpgradeable, UUPSUpgradeable {
  
    mapping(address => address) public addressToUserContracts;
    

    address[] public trustedUpdaters;
    
    mapping(address => bool) public isTrustedUpdater;

    event UpdaterAdded(address indexed updater);
    event UpdaterRemoved(address indexed updater);
    event UserContractUpdated(address indexed user, address indexed contractAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyTrustedUpdaterOrOwner() {
        require(isTrustedUpdater[msg.sender] || msg.sender == owner(), "Not a trusted updater or owner");
        _;
    }

    function addTrustedUpdater(address updater) external onlyOwner {
        require(updater != address(0), "Invalid address");
        require(!isTrustedUpdater[updater], "Already trusted updater");
        
        trustedUpdaters.push(updater);
        isTrustedUpdater[updater] = true;
        
        emit UpdaterAdded(updater);
    }

    function removeTrustedUpdater(address updater) external onlyOwner {
        require(isTrustedUpdater[updater], "Not a trusted updater");
        
        isTrustedUpdater[updater] = false;
        
        // Remove from array
        for(uint i = 0; i < trustedUpdaters.length; i++) {
            if(trustedUpdaters[i] == updater) {
                trustedUpdaters[i] = trustedUpdaters[trustedUpdaters.length - 1];
                trustedUpdaters.pop();
                break;
            }
        }
        
        emit UpdaterRemoved(updater);
    }

    function setUserContract(address user, address contractAddress) external onlyTrustedUpdaterOrOwner {
        require(user != address(0), "Invalid user address");
        require(contractAddress != address(0), "Invalid contract address");
        addressToUserContracts[user] = contractAddress;
        emit UserContractUpdated(user, contractAddress);
    }
}
