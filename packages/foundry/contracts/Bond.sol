//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./YieldProviderService.sol";
import "./interfaces/IYieldProviderService.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
contract Bond is IBond {

    BondDetails public bond;
    mapping(address => uint256) individualAmount;
    IPool public aavePool;
    IYieldProviderService public YPS;

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
            asset: _asset,
            user1: _user1,
            user2: _user2,
            totalBondAmount: totalBondAmount,
            createdAt: block.timestamp,
            isBroken: false,
            isWithdrawn: false,
            isActive: true,
            isFreezed: false
        });
        individualAmount[msg.sender] = _user1Amount;    

        address yieldProvider = address(new YieldProviderService(_aavePoolAddress));
        YPS = IYieldProviderService(yieldProvider);
        YPS.stake(tokenInAddress, msg.sender, _user1Amount);

        emit BondCreated(address(this), _user1, _user2, totalBondAmount, block.timestamp);
    }



    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */

    function stake(uint256 _amount) external override returns(BondDetails memory) {
        // we should add only owner modifier here(i mean only the users can stake)
        individualAmount[msg.sender] = _amount;
        bond.totalBondAmount += _amount;
        YPS.stake(bond.asset, address(this),  _amount);
        return bond;
    }

    function withdrawBond() external override  returns(BondDetails memory) {
        //checks
        //logic
        individualAmount[msg.sender] = 0;
        YPS.withdrawBond(bond.asset, msg.sender, individualAmount[msg.sender]);
        bond.isWithdrawn = true;
        bond.isActive = false;
        emit BondWithdrawn(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function breakBond() external override returns(BondDetails memory) {
        //checks
        //logic
        YPS.withdrawBond(bond.asset, msg.sender, bond.totalBondAmount);
        bond.isBroken = true;
        bond.isActive = false;
        emit BondBroken(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
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