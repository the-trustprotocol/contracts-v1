//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import "./IUserContract.sol";
interface ITrust {

    /*
    --------------------------
    ----------STRUCTS----------
    --------------------------
    */
    struct Analytics {
        uint256 totalUsers;
        uint256 totalBonds;
        uint256 totalAmount;
        uint256 totalWithdrawnBonds;
        uint256 totalBrokenBonds;
        uint256 totalActiveBonds;
        uint256 totalWithdrawnAmount;
        uint256 totalBrokenAmount;
    }

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    function getAnalytics() external view returns(Analytics memory);

    function createWallet(IUserContract.User memory _user) external returns(bool);
}