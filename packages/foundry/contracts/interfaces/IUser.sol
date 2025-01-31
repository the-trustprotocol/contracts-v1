// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./IBond.sol";

interface IUser {
    /*
    --------------------------
    ----------STRUCTS----------
    --------------------------
    */
    struct UserDetails {
        address userAddress;
        uint256 totalBonds;
        uint256 totalAmount;
        uint256 totalWithdrawnBonds;
        uint256 totalBrokenBonds;
        uint256 totalActiveBonds;
        uint256 totalWithdrawnAmount;
        uint256 totalBrokenAmount;
        uint256 createdAt;
    }

    /*
    --------------------------
    ----------ERRORS----------
    --------------------------
    */
    error InvalidRegistryAddress();

    /*
    --------------------------
    ----------EVENTS----------
    --------------------------
    */

    event UserCreated(address indexed user, uint256 timestamp);
    event BondDeployed(address indexed asset, address user1, address user2, uint256 totalAmount, uint256 timestamp);

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    function getBondDetails(address _bondAddress) external view returns (IBond.BondDetails memory);
    function createBond(
        IBond.BondDetails memory _bond,
        address _bondFactoryAddress,
        address _yieldProviderServiceAddress
    ) external payable returns (bool);
}
