// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IFeeSettings {
    /*
    --------------------------
    ----------STRUCTS----------
    --------------------------
    */
    struct FeeConfig {
        uint256 flatFee;
        uint256 percentageFee;
        address tokenAddress;
        address treasury;
        bool isRegistered;
    }

    /*
    --------------------------
    ----------ERRORS----------
    --------------------------
    */
    error FeePercentageCantExceed100();
    error AddressCantBeZero();

    /*
    --------------------------
    ----------EVENTS----------
    --------------------------
    */
    event FeeConfigUpdated(
        bytes4 indexed functionSelector, uint256 flatFee, uint256 percentageFee, address tokenAddress, address treasury
    );

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    function collectFees(address from, uint256 amount, bytes4 sig) external payable returns (uint256);
    function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4);
}
