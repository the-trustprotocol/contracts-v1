// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IIdentityRegistry {
    /*
    --------------------------
    ----------ERRORS----------
    --------------------------
    */

    error AddressCantBeZero();
    error IdentityTagCantBeEmpty();

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    function getResolver(string calldata identityTag) external view returns (address);
    function getAllResolvers() external view returns (address[] memory);
}
