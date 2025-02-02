// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IUserFactorySwapables {
    // Declare the function signatures for swapping settings

    function swapUserFactorySettings(address _newFactorySettings) external;

    function swapRegistry(address _registry) external;

    function swapIdentityRegistry(address _newIdentityRegistry) external;

    function swapUserSettings(address _newUserSettings) external;
}
