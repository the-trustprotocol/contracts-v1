//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

interface IYieldProviderService {
    function stake(address _assetAddress, address _user, uint256 _amount) external;
    function withdrawBond(address _assetAddress, address _user, uint256 _amount) external;
    function collectYield(address _assetAddress, uint256 _amount, address _user) external;
    function getAToken() external view returns (address);
}
