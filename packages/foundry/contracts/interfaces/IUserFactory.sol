// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IUserFactory {
    event UserCreated(address indexed owner, address indexed user);

    function createUser() external payable returns (address);


    function attestationManager() external view returns (address);

    function createUserOnBehalf(address user) external payable returns (address);
}
