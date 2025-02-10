//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import { IBond } from "./interfaces/IBond.sol";
import { IBondFactory } from "./interfaces/IBondFactory.sol";
import { IUser } from "./interfaces/IUser.sol";
// import { Bond } from "./Bond.sol";
import { IIdentityRegistry } from "./interfaces/IIdentityRegistry.sol";
import { IIdentityResolver } from "./interfaces/IIdentityResolver.sol";

import { IFeeSettings } from "./interfaces/IFeeSettings.sol";
// import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract User is IUser {
    mapping(address => IBond.BondDetails) private bondDetails;
    address[] allBonds;
    mapping(string => bool) private verifiedIdentities;

    UserDetails public user;

    IIdentityRegistry private identityRegistry;
    IFeeSettings private feeSettings;

    mapping(string => string) public slashingWords;

    constructor(address _identityRegistry, address _userWalletSettings) {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        feeSettings = IFeeSettings(_userWalletSettings);
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

    function createBond(
        IBond.BondDetails memory _bond,
        address _bondFactoryAddress,
        address _yieldProviderServiceAddress
    ) external payable override returns (address) {
        feeSettings.collectFees{ value: msg.value }(msg.sender, msg.value, msg.sig);

        IBondFactory bondFactory = IBondFactory(_bondFactoryAddress);
        address newBond = bondFactory.createBond(_bond.asset, _bond.user1, _bond.user2, _yieldProviderServiceAddress);

        bondDetails[newBond] = _bond;
        emit BondDeployed(_bond.asset, _bond.user1, _bond.user2, _bond.totalBondAmount, block.timestamp);
        return newBond;
    }

    function getBondDetails(address _bondAddress) external view returns (IBond.BondDetails memory) {
        return bondDetails[_bondAddress];
    }

    function verifyIdentity(string calldata identityTag, bytes calldata data) external returns (bool) {
        address resolver = identityRegistry.getResolver(identityTag);
        if (resolver == address(0)) revert ResolverNotFound();
        bool verified = IIdentityResolver(resolver).verify(data);
        verifiedIdentities[identityTag] = verified;
        return verified;
    }
}
