//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./interfaces/IUserContract.sol";
import "./BondContract.sol";

contract UserContract is IUserContract {

    mapping(address => IBond.BondDetails) private bondDetails;
    mapping(address => User) private userDetails;

    constructor() {
        User memory newUser = User({
            userAddress: msg.sender,
            totalBonds: 0,
            totalAmount: 0,
            totalWithdrawnBonds: 0,
            totalBrokenBonds: 0,
            totalActiveBonds: 0,
            totalWithdrawnAmount: 0,
            totalBrokenAmount: 0,
            createdAt: block.timestamp
        });
        userDetails[msg.sender] = newUser;
        emit UserCreated(msg.sender, block.timestamp);
    }
    
    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */
    function createBond(IBond.BondDetails memory _bond) external override returns(bool) {
        //checks
        address newBond = address(new BondContract( //will replace bond contract with facotry bond contract
            _bond.id,
            _bond.user1,
            _bond.user2,
            _bond.user1Amount,
            _bond.user2Amount
        ));
        bondDetails[newBond] = _bond;
        emit BondDeployed(_bond.id, _bond.user1, _bond.user2, _bond.user1Amount, _bond.user2Amount, _bond.totalBondAmount, block.timestamp);
        return true;

    }

    /*
    --------------------------
    ------VIEW FUNCTIONS------
    --------------------------
    */
    function getUserDetails(address _user) external view override returns(User memory) {
        return userDetails[_user];
    }

    function getBondDetails(address _bondAddress) external view returns(IBond.BondDetails memory) {
        return bondDetails[_bondAddress];
    }
}