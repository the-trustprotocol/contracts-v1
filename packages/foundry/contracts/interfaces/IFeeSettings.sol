// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IFeeSettings {
    struct FeeConfig {
        uint256 flatFee;
        uint256 percentageFee;
        address tokenAddress;
        address treasury;
        bool isRegistered;
    }

    event FeeConfigUpdated(
        bytes4 indexed functionSelector, uint256 flatFee, uint256 percentageFee, address tokenAddress, address treasury
    );

    function collectFees(address from, uint256 amount) external payable returns (uint256);
    function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4);
}
