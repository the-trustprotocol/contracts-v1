// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IIdentityRegistry {
    function getResolver(string calldata identityTag) external view returns (address);
    function getAllResolvers() external view returns (address[] memory);
}
