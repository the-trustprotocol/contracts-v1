//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./interfaces/IBondFactory.sol";
import "./interfaces/IUser.sol";
import "./Bond.sol";
import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/IIdentityResolver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract User is IUser, Ownable2StepUpgradeable, UUPSUpgradeable {
    mapping(address => IBond.BondDetails) private bondDetails;
    mapping(string => bool) private verifiedIdentities;

    UserDetails public user;

    IBondFactory private bondFactory;
    IIdentityRegistry private identityRegistry;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _identityRegistry, address _bondFactoryAddress) external initializer {
        if (_identityRegistry == address(0)) revert InvalidRegistryAddress();

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        identityRegistry = IIdentityRegistry(_identityRegistry);
        bondFactory = IBondFactory(_bondFactoryAddress);

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
        address _aavePoolAddress,
        address _uiPoolDataAddress,
        address _ypsFactoryAddress
    ) external override returns (bool) {
        address newBond = bondFactory.createBond(
            _bond.asset,
            _bond.user1,
            _bond.user2,
            _bond.totalBondAmount,
            _aavePoolAddress,
            _uiPoolDataAddress,
            _ypsFactoryAddress
        );

        bondDetails[newBond] = _bond;
        emit BondDeployed(_bond.asset, _bond.user1, _bond.user2, _bond.totalBondAmount, block.timestamp);
        return true;
    }

    function getBondDetails(address _bondAddress) external view returns (IBond.BondDetails memory) {
        return bondDetails[_bondAddress];
    }

    function verifyIdentity(string calldata identityTag, bytes calldata data) external returns (bool) {
        address resolver = identityRegistry.getResolver(identityTag);
        require(resolver != address(0), "Resolver not found");

        bool verified = IIdentityResolver(resolver).verify(data);
        verifiedIdentities[identityTag] = verified;
        return verified;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
