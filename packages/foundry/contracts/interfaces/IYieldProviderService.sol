// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IYieldProviderService {
    function stake(
        address _assetAddress, 
        address _user, 
        uint256 _amount
    ) external;

    function withdraw(
        address _assetAddress, 
        address _user, 
        uint256 _amount
    ) external;
}
