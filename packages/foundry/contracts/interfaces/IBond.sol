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

    error BondNotActive();
    error BondIsFreezed();
    error UserIsNotAOwnerForThisBond();
    error NoCollateralRequested();
    error CantAcceptOwnCollateral();
    error NothingToClaim();

    /*
    --------------------------
    ----------EVENTS----------
    --------------------------
    */
    event BondCreated(
        address indexed bondAddress, address user1, address user2, uint256 totalBondAmount, uint256 createdAt
    );
    event BondWithdrawn(
        address indexed bondAddress,
        address user1,
        address user2,
        address indexed withdrawnBy,
        uint256 totalBondAmount,
        uint256 createdAt
    );
    event BondBroken(
        address indexed bondAddress,
        address user1,
        address user2,
        address indexed brokenBy,
        uint256 totalBondAmount,
        uint256 createdAt
    );
    event BondFreezed(
        address indexed bondAddress,
        address user1,
        address user2,
        address indexed freezedbY,
        uint256 totalBondAmount,
        uint256 createdAt
    );

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    function stake(address stakingBy, uint256 _amount) external returns (BondDetails memory);
    function withdraw(address to) external returns (BondDetails memory);
    function breakBond(address _to) external returns (BondDetails memory);
    function requestForCollateral() external;
    function acceptForCollateral() external;
    function unfreeze() external;
    function yieldServiceProvider() external view returns (address);
    function collectYield(address _aAsset, address _user) external;
}
