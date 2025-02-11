// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IBond } from "./IBond.sol";

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
    error ResolverNotFound();

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
}
