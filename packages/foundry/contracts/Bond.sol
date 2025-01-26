//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
contract Bond is IBond {

    BondDetails public bond;
    mapping(uint256 => BondDetails) public bondDetails;
     mapping(address => uint256) individualAmount;
    IPool public aavePool;

    constructor(
        uint256 _id,
        address _asset,
        address _user1,
        address _user2,
        uint256 _user1Amount,
        address _aavePoolAddress,
        address tokenInAddress
    ) {

        aavePool = IPool(_aavePoolAddress);
        uint256 totalBondAmount = _user1Amount; //initially when we create a bond we have only user 1 amount, there is no point of adding user2 amount always it will be 0
        bond = BondDetails({
            id: _id, //will remove if not useful
            asset: _asset,
            user1: _user1,
            user2: _user2,
            // individualAmount[msg.sender] : _user1Amount,
            totalBondAmount: totalBondAmount,
            createdAt: block.timestamp,
            isBroken: false,
            isWithdrawn: false,
            isActive: true,
            isFreezed: false
        });
        individualAmount[msg.sender] = _user1Amount;
        bondDetails[_id] = bond;
        supply(tokenInAddress, _user1Amount, address(this));

        emit BondCreated(_id, _user1, _user2, totalBondAmount, block.timestamp);
    }

    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */

    function stake(uint256 _id, uint256 _amount) external override {
        // we should add only owner modifier here(i mean only the users can stake)
        BondDetails storage _bond = bondDetails[_id];
        _bond.totalBondAmount += _amount;
        supply(_bond.asset, _amount, address(this));
    }

    function withdrawBond(uint256 _id) external override {
        //checks
        //logic
        aavePool.withdraw(bond.asset, individualAmount[msg.sender], msg.sender);
        bond.isWithdrawn = true;
        bond.isActive = false;
        emit BondWithdrawn(_id, bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
    }

    function breakBond(uint256 _id) external override {
        //checks
        //logic
        bond.isBroken = true;
        bond.isActive = false;
        emit BondBroken(_id, bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
    }

    function collectYield(uint256 _id) external override {}

    function freezeBond(uint256 _id) external override {}

    /*
    ----------------------------------
    ---------PRIVATE FUNCTIONS--------
    ----------------------------------
    */

    function supply( address asset, uint256 amount, address onBehalfOf) public {
        aavePool.supply(asset, amount, onBehalfOf, 0);
    }
}