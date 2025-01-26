//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

interface IBond {

    /*
    --------------------------
    ----------STRUCTS----------
    --------------------------
    */
    struct BondDetails {
        address asset;
        address user1;
        address user2;
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
    event BondCreated(address indexed bondAddress, address user1, address user2, uint256 totalBondAmount, uint256 createdAt);
    event BondWithdrawn(address indexed bondAddress, address user1, address user2, address indexed withdrawnBy, uint256 totalBondAmount, uint256 createdAt);
    event BondBroken(address indexed bondAddress, address user1, address user2, address indexed brokenBy, uint256 totalBondAmount, uint256 createdAt);
    event BondFreezed(address indexed bondAddress, address user1, address user2, address indexed freezedbY, uint256 totalBondAmount, uint256 createdAt);

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    // function getBondDetails(uint256 _id) external view returns(BondDetails memory);
    function stake(uint256 _amount) external returns (BondDetails memory);
    function withdrawBond() external returns (BondDetails memory);
    function breakBond() external returns (BondDetails memory);
    function freezeBond(uint256 _id) external;
    function collectYield(uint256 _id) external;
}