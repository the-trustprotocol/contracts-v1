// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;



import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserFactorySettings is Ownable2StepUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    struct FeeConfig {
        uint256 flatFee;
        uint256 percentageFee;  
        address tokenAddress;    
        address treasury;     
        bool isRegistered;     
    }

    // Maps function selector to fee configuration
    mapping(bytes4 => FeeConfig) public functionFees;

    event FeeConfigUpdated(
        bytes4 indexed functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress,
        address treasury
    );

    function registerFunctionFees(
        bytes4 functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress,
        address treasury
    ) external onlyOwner {
        require(percentageFee <= 10000, "Percentage fee cannot exceed 100%");
        require(treasury != address(0), "Invalid treasury address");
        
        functionFees[functionSelector] = FeeConfig({
            flatFee: flatFee,
            percentageFee: percentageFee,
            tokenAddress: tokenAddress,
            treasury: treasury,
            isRegistered: true
        });

        emit FeeConfigUpdated(
            functionSelector,
            flatFee,
            percentageFee,
            tokenAddress,
            treasury
        );
    }

    function deregisterFunctionFees(bytes4 functionSelector) external onlyOwner {
        delete functionFees[functionSelector];
    }

    function collectFees(address from, uint256 amount) external payable returns (uint256) {
        bytes4 functionSelector = msg.sig;
        FeeConfig memory feeConfig = functionFees[functionSelector];
        
        if (!feeConfig.isRegistered) {
            require(msg.value == 0, "Fees not configured for this function");
            return 0;
        }

        uint256 totalFee = feeConfig.flatFee;
        if (amount > 0) {
            totalFee += (amount * feeConfig.percentageFee) / 10000;
        }

        if (feeConfig.tokenAddress == address(0)) {
            // Native token
            require(msg.value >= totalFee, "Insufficient fee");
            if (msg.value > totalFee) {
                payable(from).transfer(msg.value - totalFee);
            }
            payable(feeConfig.treasury).transfer(totalFee);
        } else {
            // ERC20 token
            require(msg.value == 0, "Do not send ETH with ERC20 fee");
            IERC20(feeConfig.tokenAddress).transferFrom(
                from,
                feeConfig.treasury,
                totalFee
            );
        }

        return totalFee;
    }

    function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(functionSignature)));
    }
}