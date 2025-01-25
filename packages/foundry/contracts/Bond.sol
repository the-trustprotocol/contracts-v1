//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";

contract Bond is IBond {

    BondDetails public bond;

    constructor(
        uint256 _id,
        address _user1,
        address _user2,
        uint256 _user1Amount,
        uint256 _user2Amount
    ) {

        uint256 totalBondAmount = _user1Amount + _user2Amount;
        bond = BondDetails({
            id: _id, //will remove if not useful
            user1: _user1,
            user2: _user2,
            user1Amount: _user1Amount,
            user2Amount: _user2Amount,
            totalBondAmount: totalBondAmount,
            createdAt: block.timestamp,
            isBroken: false,
            isWithdrawn: false,
            isActive: true,
            isFreezed: false
        });

        emit BondCreated(_id, _user1, _user2, _user1Amount, _user2Amount, totalBondAmount, block.timestamp);
    }

    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */

    function withdrawBond(uint256 _id) external override returns(BondDetails memory) {
        //checks
        //logic
        bond.isWithdrawn = true;
        bond.isActive = false;
        emit BondWithdrawn(_id, bond.user1, bond.user2, bond.user1Amount, bond.user2Amount, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function breakBond(uint256 _id) external override returns(BondDetails memory) {
        //checks
        //logic
        bond.isBroken = true;
        bond.isActive = false;
        emit BondBroken(_id, bond.user1, bond.user2, bond.user1Amount, bond.user2Amount, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function collectYield(uint256 _id) external override returns(BondDetails memory) {}

    function freezeBond(uint256 _id) external override returns(BondDetails memory) {}

    // function getBondDetails(uint256 _id) external view override returns(BondDetails memory) {} // will add if needed
}