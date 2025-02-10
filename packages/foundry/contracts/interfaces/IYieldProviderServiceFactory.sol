// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IYieldProviderServiceFactory {
    function createYPS(address _aavePoolAddress, address _aToken, address _token) external returns (address);
}
