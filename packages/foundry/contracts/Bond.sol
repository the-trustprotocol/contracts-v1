//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./YieldProviderService.sol";
import "./interfaces/IYieldProviderService.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Bond is IBond, Ownable2StepUpgradeable, UUPSUpgradeable, ReentrancyGuard {

    BondDetails public bond;
    mapping(address => uint256) individualAmount;
    IPool public aavePool;
    IYieldProviderService public YPS;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _asset,
        address _user1,
        address _user2,
        uint256 _user1Amount,
        address _aavePoolAddress
    ) external initializer {
        __Ownable_init(msg.sender); //need to think who should be the owner
        __UUPSUpgradeable_init();

        aavePool = IPool(_aavePoolAddress);
        uint256 totalBondAmount = _user1Amount;

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

        individualAmount[_user1] = _user1Amount;

        address yieldProvider = address(new YieldProviderService(_aavePoolAddress));
        YPS = IYieldProviderService(yieldProvider);
        YPS.stake(_asset, _user1, _user1Amount);

        emit BondCreated(address(this), _user1, _user2, totalBondAmount, block.timestamp);
    }


    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */

    function stake(uint256 _amount) external nonReentrant override returns(BondDetails memory) {
        _onlyActive();
        // we should add only owner modifier here(i mean only the users can stake)
        individualAmount[msg.sender] = _amount;
        bond.totalBondAmount += _amount;
        YPS.stake(bond.asset, address(this),  _amount);
        return bond;
    }

    function withdrawBond() external nonReentrant override returns(BondDetails memory) {
        _onlyActive();
        _freezed();
        uint256 withdrawable = individualAmount[msg.sender];
        individualAmount[msg.sender] = 0;
        YPS.withdrawBond(bond.asset, msg.sender, withdrawable);
        bond.isWithdrawn = true;
        bond.isActive = false;
        emit BondWithdrawn(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function breakBond() external nonReentrant override returns(BondDetails memory) {
        _onlyActive();
        _freezed();
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

    function _onlyActive() private view {
        if(!bond.isActive) revert BondNotActive();
    }

    function _freezed() private view {
        if(bond.isFreezed) revert BondIsFreezed();
    }

}