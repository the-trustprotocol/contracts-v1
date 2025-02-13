//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import { IBond } from "./interfaces/IBond.sol";
import { IBondFactory } from "./interfaces/IBondFactory.sol";
import { IUser } from "./interfaces/IUser.sol";
// import { Bond } from "./Bond.sol";
import { IIdentityRegistry } from "./interfaces/IIdentityRegistry.sol";
import { IIdentityResolver } from "./interfaces/IIdentityResolver.sol";
import { IFeeSettings } from "./interfaces/IFeeSettings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { UserFactory } from "./factories/UserFactory.sol";

import { IYieldProviderService } from "./interfaces/IYieldProviderService.sol";

contract User is Ownable, IUser {
    address[] allBonds;
    mapping(string => bool) private verifiedIdentities;

    UserDetails public user;

    UserFactory public userFactory;

    IIdentityRegistry private identityRegistry;
    IFeeSettings private feeSettings;

    mapping(string => string) public slashingWords;

    constructor(address _user, address _identityRegistry, address _userWalletSettings, address _userFactory)
        Ownable(_user)
    {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        feeSettings = IFeeSettings(_userWalletSettings);
        userFactory = UserFactory(_userFactory);
        user = UserDetails({
            userAddress: _user,
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
    function createBond(
        address partner,
        address asset,
        address yieldServiceProvider,
        uint256 initialAmount,
        address bondFactoryAddresss
    ) public payable onlyOwner returns (address) {
        IBondFactory bondFactory = IBondFactory(bondFactoryAddresss);
        address partnerUserAddress = userFactory.createUser(partner);
        address newBond = bondFactory.createBond(asset, address(this), partnerUserAddress, yieldServiceProvider);
        allBonds.push(newBond);
        user.totalBonds += 1;
        user.totalActiveBonds += 1;
        user.totalAmount += initialAmount;

        User(partnerUserAddress).addBond(newBond);
        if (initialAmount > 0) {
            IBond bond = IBond(newBond);
            IERC20(IYieldProviderService(yieldServiceProvider).depositToken()).transferFrom(
                msg.sender, address(this), initialAmount
            );
            IERC20(IYieldProviderService(yieldServiceProvider).depositToken()).approve(address(bond), initialAmount);
            bond.stake(address(this), initialAmount);
        }
        return newBond;
    }

    function stake(address bondAddress, uint256 amount) public payable onlyOwner {
        IBond bond = IBond(bondAddress);
        IERC20(IYieldProviderService(bond.yieldServiceProvider()).depositToken()).transferFrom(
            msg.sender, address(this), amount
        );
        IERC20(IYieldProviderService(bond.yieldServiceProvider()).depositToken()).approve(bondAddress, amount);
        user.totalAmount += amount;
        bond.stake(address(this), amount);
    }

    function addBond(address bondAddress) public {
        allBonds.push(bondAddress);
        user.totalBonds += 1;
        user.totalActiveBonds += 1;
    }

    function withdraw(address bondAddress) public payable onlyOwner {
        IBond bond = IBond(bondAddress);
        bond.withdraw(address(this));
        IERC20 depositToken = IERC20(IYieldProviderService(bond.yieldServiceProvider()).depositToken());
        uint256 balance = depositToken.balanceOf(address(this));
        user.totalWithdrawnBonds += 1;
        user.totalActiveBonds -= 1;
        user.totalWithdrawnAmount += balance;
        depositToken.transfer(owner(), balance);
    }

    function breakBond(address bondAddress) public payable onlyOwner {
        IBond bond = IBond(bondAddress);
        bond.breakBond(address(this));
        IERC20 depositToken = IERC20(IYieldProviderService(bond.yieldServiceProvider()).depositToken());
        uint256 balance = depositToken.balanceOf(address(this));
        user.totalBrokenBonds += 1;
        user.totalActiveBonds -= 1;
        user.totalBrokenAmount += balance;
        depositToken.transfer(owner(), balance);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        user.userAddress = newOwner;
        _transferOwnership(newOwner);
    }

    function getAllBonds() public view returns (address[] memory) {
        return allBonds;
    }

    function verifyIdentity(string calldata identityTag, bytes calldata data) external returns (bool) {
        address resolver = identityRegistry.getResolver(identityTag);
        if (resolver == address(0)) revert ResolverNotFound();
        bool verified = IIdentityResolver(resolver).verify(data);
        verifiedIdentities[identityTag] = verified;
        return verified;
    }
}
