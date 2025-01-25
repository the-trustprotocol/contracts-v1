//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

interface IBond {

    /*
    --------------------------
    ----------STRUCTS----------
    --------------------------
    */
    struct BondDetails {
        uint256 id;
        address user1;
        address user2;
        uint256 user1Amount;
        uint256 user2Amount;
        uint256 totalBondAmount;
        uint256 createdAt;
        bool isBroken;
        bool isWithdrawn;
        bool isActive;
        bool isFreezed;
    }

    /*
    --------------------------
    ----------ERRORS----------
    --------------------------
    */


    /*
    --------------------------
    ----------EVENTS----------
    --------------------------
    */
    event BondCreated(uint256 id, address user1, address user2, uint256 user1Amount, uint256 user2Amount, uint256 totalBondAmount, uint256 createdAt);
    event BondWithdrawn(uint256 id, address user1, address user2, uint256 user1Amount, uint256 user2Amount, uint256 totalBondAmount, uint256 createdAt);
    event BondBroken(uint256 id, address user1, address user2, uint256 user1Amount, uint256 user2Amount, uint256 totalBondAmount, uint256 createdAt);
    event BondFreezed(uint256 id, address user1, address user2, uint256 user1Amount, uint256 user2Amount, uint256 totalBondAmount, uint256 createdAt);

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    // function getBondDetails(uint256 _id) external view returns(BondDetails memory);
    function withdrawBond(uint256 _id) external returns(BondDetails memory);
    function breakBond(uint256 _id) external returns(BondDetails memory);
    function freezeBond(uint256 _id) external returns(BondDetails memory);
    function collectYield(uint256 _id) external returns(BondDetails memory);
}