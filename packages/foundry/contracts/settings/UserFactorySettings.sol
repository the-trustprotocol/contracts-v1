// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;



import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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
        uint256 percentageFee;  // in basis points (1% = 100)
        address tokenAddress;    // address(0) for native token
        bool isRegistered;      // whether this function has fees configured
    }

    // Maps function selector to fee configuration
    mapping(bytes4 => FeeConfig) public functionFees;

    event FeeConfigUpdated(
        bytes4 indexed functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress
    );

    function registerFunctionFees(
        bytes4 functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress
    ) external onlyOwner {
        require(percentageFee <= 10000, "Percentage fee cannot exceed 100%");
        
        functionFees[functionSelector] = FeeConfig({
            flatFee: flatFee,
            percentageFee: percentageFee,
            tokenAddress: tokenAddress,
            isRegistered: true
        });

        emit FeeConfigUpdated(
            functionSelector,
            flatFee,
            percentageFee,
            tokenAddress
        );
    }

    function deregisterFunctionFees(bytes4 functionSelector) external onlyOwner {
        delete functionFees[functionSelector];
    }

    function collectFees(uint256 amount) external payable returns (uint256) {
        // Get the function that called this method
        bytes4 functionSelector = msg.sig;
        
        // Get fee config for this function
        FeeConfig memory feeConfig = functionFees[functionSelector];
        
        // If function is not registered, return without collecting fees
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
                payable(msg.sender).transfer(msg.value - totalFee);
            }
        } else {
            // ERC20 token
            require(msg.value == 0, "Do not send ETH with ERC20 fee");
            IERC20Upgradeable(feeConfig.tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalFee
            );
        }

        return totalFee;
    }

    // Helper function to get a function's selector
    function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(functionSignature)));
    }
}