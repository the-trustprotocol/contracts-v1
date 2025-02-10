// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IYieldProviderService {
    function stake(address _user, uint256 _amount) external;

    function withdraw(address _user, uint256 _amount, address _to) external;

    function depositToken() external view returns (address);

    function balanceOfToken(address addr) external returns (uint256);

    function yieldToken() external returns (address);
}
