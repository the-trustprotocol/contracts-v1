//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IBond } from "./interfaces/IBond.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";
// contracts/access/Ownable2Step.sol
// import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Bond is IBond, ReentrancyGuard {
    address public collateralRequestedBy;
    uint256 public constant MAX_BPS = 10000;

    mapping(address => uint256) public individualAmount;
    mapping(address => uint256) public claimableYield;
    mapping(address => uint256) public individualPercentage;
    //we can replace the above 3 mappings with a struct and mapping of that struct
    mapping(address => bool) public isUser;

    IYieldProviderService public yps;

    BondDetails public bond;

    constructor(address _asset, address _user1, address _user2, address _yieldProviderServiceAddress) {
        bond = BondDetails({
            asset: _asset,
            user1: _user1,
            user2: _user2,
            totalBondAmount: 0,
            createdAt: block.timestamp,
            isBroken: false,
            isWithdrawn: false,
            isActive: true,
            isFreezed: false
        });
        individualPercentage[_user1] = 100;
        isUser[_user1] = true;
        isUser[_user2] = true;
        yps = IYieldProviderService(_yieldProviderServiceAddress);
        emit BondCreated(address(this), _user1, _user2, 0, block.timestamp);
    }

    /*
    ----------------------------------
    ------EXTERNAL OPEN FUNCTIONS-----
    ----------------------------------
    */

    function stake(address user, uint256 _amount) external override nonReentrant returns (BondDetails memory) {
        _onlyActive();

        //always the token In should be same as the bond asset
        //seems like the above comment no need to be, if we settle in eth and stake in any coin...
        individualAmount[user] += _amount;
        bond.totalBondAmount += _amount;
        individualPercentage[bond.user1] = (individualAmount[bond.user1] * MAX_BPS) / bond.totalBondAmount;
        individualPercentage[bond.user2] = (individualAmount[bond.user2] * MAX_BPS) / bond.totalBondAmount;
        IERC20(yps.depositToken()).transferFrom(user, address(this), _amount);
        IERC20(yps.depositToken()).approve(address(yps), _amount);
        yps.stake(address(this), _amount);
        return bond;
    }

    function withdraw(address _user) external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();
        _freezed();
        _calcYield(yps.yieldToken());
        uint256 withdrawable = individualAmount[_user] + claimableYield[_user];
        individualAmount[_user] = 0;
        bond.isWithdrawn = true;
       
        IERC20(yps.yieldToken()).approve(address(yps), withdrawable);
        yps.withdraw(address(this), withdrawable, _user);
        emit BondWithdrawn(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function breakBond(address _user) external override nonReentrant returns (BondDetails memory) {
        _onlyActive();
        _onlyUser();
        _freezed();
        _calcYield(yps.yieldToken());
        bond.isBroken = true;
        bond.isActive = false;
        individualAmount[bond.user1] = 0;
        individualAmount[bond.user2] = 0;

        uint256 withdrawable = IERC20(yps.yieldToken()).balanceOf(address(this));
        IERC20(yps.yieldToken()).approve(address(yps), withdrawable);
        yps.withdraw(address(this), withdrawable, _user);
        emit BondBroken(address(this), bond.user1, bond.user2, msg.sender, bond.totalBondAmount, block.timestamp);
        return bond;
    }

    function withdrawable(address user) public returns (uint256) {
        _calcYield(IYieldProviderService(yps).yieldToken());
        return individualAmount[user] + claimableYield[user];
    }

    function withdrawableYield(address user) public returns (uint256) {
        _calcYield(IYieldProviderService(yps).yieldToken());
        return claimableYield[user];
    }

    function collectYield(address _aAsset, address _user) external override {
        _onlyActive();
        _onlyUser();
        _freezed();
        _calcYield(_aAsset);
        uint256 userClaimableYield = claimableYield[_user];
        if (userClaimableYield == 0) revert NothingToClaim();
        claimableYield[_user] = 0;
        yps.withdraw(address(this), userClaimableYield, _user);
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

    function unfreeze() external override {
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

    function _calcYield(address _aAsset) private {
        // address aToken = yps.getAToken();
        address aToken = _aAsset;
        uint256 aTokenBalance = IERC20(aToken).balanceOf(address(this));
        uint256 yield = aTokenBalance - bond.totalBondAmount; // only works with stable coins, if the all aTokens are ERC20
        claimableYield[bond.user1] = (individualPercentage[bond.user1] * yield) / MAX_BPS;
        claimableYield[bond.user2] = (individualPercentage[bond.user2] * yield) / MAX_BPS;
    }

    function yieldServiceProvider() external view override returns (address) {
        return address(yps);
    }
}
