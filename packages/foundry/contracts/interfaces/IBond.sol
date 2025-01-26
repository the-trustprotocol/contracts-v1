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
        address asset;
        address user1;
        address user2;
        // mapping(address => uint256) individualAmount;
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
    event BondCreated(uint256 indexed id, address user1, address user2, uint256 totalBondAmount, uint256 createdAt);
    event BondWithdrawn(uint256 indexed id, address user1, address user2, address indexed withdrawnBy, uint256 totalBondAmount, uint256 createdAt);
    event BondBroken(uint256 indexed id, address user1, address user2, address indexed brokenBy, uint256 totalBondAmount, uint256 createdAt);
    event BondFreezed(uint256 indexed id, address user1, address user2, address indexed freezedbY, uint256 totalBondAmount, uint256 createdAt);

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    // function getBondDetails(uint256 _id) external view returns(BondDetails memory);
    function stake(uint256 _id, uint256 _amount) external;
    function withdrawBond(uint256 _id) external;
    function breakBond(uint256 _id) external;
    function freezeBond(uint256 _id) external;
    function collectYield(uint256 _id) external;
}