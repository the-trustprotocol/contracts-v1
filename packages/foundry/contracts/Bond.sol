//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IBond } from "./interfaces/IBond.sol";
import "./YieldProviderService.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";
import { IPool } from "@aave/interfaces/IPool.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IPoolAddressesProvider } from "@aave/interfaces/IPoolAddressesProvider.sol";
// import {IUiPoolDataProviderV3} from

contract Bond is IBond, Ownable2StepUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    BondDetails public bond;
    mapping(address => uint256) individualAmount;
    mapping(address => bool) public isUser;
    IPool public aavePool;
    IYieldProviderService public YPS;
    address public aavePoolAddress;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _asset, address _user1, address _user2, uint256 _user1Amount, address _aavePoolAddress)
        external
        initializer
    {
        __Ownable_init(msg.sender); //need to think who should be the owner, we might not need this
        __ReentrancyGuard_init();
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
        isUser[_user1] = true;
        isUser[_user2] = true;
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

    function stake(uint256 _amount) external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();

        individualAmount[msg.sender] = _amount;
        bond.totalBondAmount += _amount;
        YPS.stake(bond.asset, address(this), _amount);
        return bond;
    }

    function withdrawBond() external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();
        _freezed();
        uint256 withdrawable = individualAmount[msg.sender];
        individualAmount[msg.sender] = 0;
        YPS.withdrawBond(bond.asset, msg.sender, withdrawable);
        bond.isWithdrawn = true;
        bond.isActive = false;
        emit BondWithdrawn(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function breakBond() external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();
        _freezed();
        YPS.withdrawBond(bond.asset, msg.sender, bond.totalBondAmount);
        bond.isBroken = true;
        bond.isActive = false;
        emit BondBroken(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function collectYield() external override {
        _onlyUser();
        uint256 claimableYield = 100 - IERC20(bond.asset).balanceOf(address(this)); //100 will replaced by the balance of aTokens.
        YPS.withdrawBond(bond.asset, msg.sender, claimableYield);
    }

    function freezeBond(uint256 _id) external override { }

    /*
    ----------------------------------
    ---------PRIVATE FUNCTIONS--------
    ----------------------------------
    */

    function _onlyActive() private view {
        if (!bond.isActive) revert BondNotActive();
    }

    function _freezed() private view {
        if (bond.isFreezed) revert BondIsFreezed();
    }

    function _onlyUser() private view {
        if (!isUser[msg.sender]) revert UserIsNotAOwnerForThisBond();
    }

    function _calcYield(address _user) private returns (uint256) { }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
