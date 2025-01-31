// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFeeSettings} from "../interfaces/IFeeSettings.sol";

contract FeeSettings is IFeeSettings {
    mapping(bytes4 => FeeConfig) public functionFees;

    function _registerFunctionFees(
        bytes4 functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress,
        address treasury
    ) internal {
        // require(percentageFee <= 10000, "Percentage fee cannot exceed 100%");
        if(percentageFee > 10000) revert FeePercentageCantExceed100();
        // require(treasury != address(0), "Invalid treasury address");
        if(treasury == address(0)) revert AddressCantBeZero();

        functionFees[functionSelector] = FeeConfig({
            flatFee: flatFee,
            percentageFee: percentageFee,
            tokenAddress: tokenAddress,
            treasury: treasury,
            isRegistered: true
        });

        emit FeeConfigUpdated(functionSelector, flatFee, percentageFee, tokenAddress, treasury);
    }

    function _deregisterFunctionFees(bytes4 functionSelector) internal {
        delete functionFees[functionSelector];
    }

    function collectFees(address from, uint256 amount, bytes4 sig) external payable virtual returns (uint256) {
        bytes4 functionSelector = sig;
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
            IERC20(feeConfig.tokenAddress).transferFrom(from, feeConfig.treasury, totalFee);
        }

        return totalFee;
    }

    function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(functionSignature)));
    }
}
