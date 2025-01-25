//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import "./IBond.sol";

interface IUserContract {

    struct User {
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

    event UserCreated(address userAddress, uint256 createdAt);
    event BondDeployed(uint256 id, address user1, address user2, uint256 user1Amount, uint256 user2Amount, uint256 totalBondAmount, uint256 createdAt);

    function getUserDetails(address _userAddress) external view returns(User memory);
    function getBondDetails(address _bondAddress) external view returns(IBond.BondDetails memory);
    function createBond(IBond.BondDetails memory _bond) external returns(bool);
}