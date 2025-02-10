// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFeeSettings } from "../interfaces/IFeeSettings.sol";

contract FeeSettings is IFeeSettings {
    mapping(bytes4 => FeeConfig) public functionFees;

    // Define a new event for successful fee collection, including the token address

    function _registerFunctionFees(
        bytes4 functionSelector,
        uint256 flatFee,
        uint256 percentageFee,
        address tokenAddress,
        address treasury
    ) internal {
        if (percentageFee > 1000) revert FeePercentageCantExceed100();

        if (treasury == address(0)) revert AddressCantBeZero();

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
            return 0;
        }

        uint256 totalFee = feeConfig.flatFee;
        if (amount > 0) {
            totalFee += (amount * feeConfig.percentageFee) / 1000;
        }

        if (feeConfig.tokenAddress == address(0)) {
            // payable(feeConfig.treasury).transfer(totalFee);
            (bool success,) = payable(feeConfig.treasury).call{ value: totalFee }("");
            require(success, "Transfer failed");
            if (msg.value > totalFee) {
                payable(from).transfer(msg.value - totalFee);
            }
            return totalFee;
        } else {
            // ERC20 token
            require(msg.value == 0, "Do not send ETH with ERC20 fee");
            IERC20(feeConfig.tokenAddress).transferFrom(from, feeConfig.treasury, totalFee);
        }

        // Emit the FeesCollected event, including the token address
        emit FeesCollected(from, functionSelector, totalFee, feeConfig.tokenAddress);

        return totalFee;
    }

    function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(functionSignature)));
    }
}
