//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IBond } from "./interfaces/IBond.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract Bond is IBond, Ownable2StepUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    address public collateralRequestedBy;

    uint256 public constant MAX_BPS = 10000;

    mapping(address => uint256) public individualAmount;
    mapping(address => uint256) public claimableYield;
    mapping(address => uint256) public individualPercentage;
    //we can replace the above 3 mappings with a struct and mapping of that struct
    mapping(address => bool) public isUser;

    IYieldProviderService public yps;

    BondDetails public bond;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _asset,
        address _user1,
        address _user2,
        uint256 _user1Amount,
        address _yieldProviderServiceAddress
    ) external initializer {
        __Ownable_init(msg.sender); //need to think who should be the owner, we might not need this
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

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
        individualPercentage[_user1] = 100;
        isUser[_user1] = true;
        isUser[_user2] = true;
        yps = IYieldProviderService(_yieldProviderServiceAddress);
        yps.stake(_asset, _user1, _user1Amount);

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
        //always the token In should be same as the bond asset
        individualAmount[msg.sender] = _amount;
        bond.totalBondAmount += _amount;
        individualPercentage[bond.user1] = (individualAmount[bond.user1] * MAX_BPS) / bond.totalBondAmount;
        individualPercentage[bond.user2] = (individualAmount[bond.user2] * MAX_BPS) / bond.totalBondAmount;
        yps.stake(bond.asset, address(this), _amount);
        return bond;
    }

    function withdrawBond() external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();
        _freezed();
        uint256 withdrawable = individualAmount[msg.sender];
        individualAmount[msg.sender] = 0;
        bond.isWithdrawn = true;
        bond.isActive = false;
        yps.withdrawBond(bond.asset, msg.sender, withdrawable);
        emit BondWithdrawn(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function breakBond() external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();
        _freezed();
        bond.isBroken = true;
        bond.isActive = false;
        yps.withdrawBond(bond.asset, msg.sender, bond.totalBondAmount);
        emit BondBroken(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function collectYield() external override {
        _onlyUser();
        _freezed();
        _calcYield();
        if (claimableYield[msg.sender] == 0) revert NothingToClaim();
        uint256 userClaimableYield = claimableYield[msg.sender];
        claimableYield[msg.sender] = 0;
        yps.withdrawBond(bond.asset, msg.sender, userClaimableYield);
    }

    function requestForCollateral() external override {
        _onlyActive();
        _onlyUser();
        _freezed();
        collateralRequestedBy = msg.sender;
    }

    function acceptForCollateral() external override {
        _onlyActive();
        _onlyUser();
        _freezed();
        if (collateralRequestedBy == address(0)) revert NoCollateralRequested();
        if (collateralRequestedBy == msg.sender) revert CantAcceptOwnCollateral();
        freezeBond();
    }

    function unfreezeBond() external override {
        _onlyActive();
        //need to think who should be able to call this function, based on to whom we give access to the bond when its freezed
        bond.isFreezed = true;
        collateralRequestedBy = address(0);
    }

    /*
    ----------------------------------
    ---------PRIVATE FUNCTIONS--------
    ----------------------------------
    */

    function freezeBond() private {
        bond.isFreezed = true;
        // to whom we can give the access/authority of this bond ??????????
    }

    function _onlyActive() private view {
        if (!bond.isActive) revert BondNotActive();
    }

    function _freezed() private view {
        if (bond.isFreezed) revert BondIsFreezed();
    }

    function _onlyUser() private view {
        if (!isUser[msg.sender]) revert UserIsNotAOwnerForThisBond();
    }

    function _calcYield() private {
        address aToken = yps.getAToken();
        uint256 aTokenBalance = IERC20(aToken).balanceOf(address(this));
        uint256 yield = aTokenBalance - bond.totalBondAmount; // only works with stable coins, if the all aTokens are ERC20
        claimableYield[bond.user1] = (individualPercentage[bond.user1] * yield) / MAX_BPS;
        claimableYield[bond.user2] = (individualPercentage[bond.user2] * yield) / MAX_BPS;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
