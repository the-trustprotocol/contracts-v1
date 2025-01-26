//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./interfaces/IUser.sol";
import "./Bond.sol";

contract User is IUser {

    mapping(address => IBond.BondDetails) private bondDetails;
    UserDetails public user;

    constructor() {
        user = UserDetails({
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
        emit UserCreated(msg.sender, block.timestamp);
    }
    
    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */
    function createBond(IBond.BondDetails memory _bond) external override returns(bool) {
        //checks
        address newBond = address(new Bond( //will replace bond contract with facotry bond contract
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
    function getBondDetails(address _bondAddress) external view returns(IBond.BondDetails memory) {
        return bondDetails[_bondAddress];
    }
}