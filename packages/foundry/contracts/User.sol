//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./interfaces/IUser.sol";
import "./Bond.sol";
import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/IIdentityResolver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IBondFactory {
    function createBond(
        address _asset,
        address _user1,
        address _user2,
        uint256 _user1Amount,
        uint256 _user2Amount,
        address _aavePoolAddress,
        address _tokenInAddress
    ) external returns (address);
}

contract User is IUser {
    IIdentityRegistry private immutable identityRegistry;
    mapping(address => IBond.BondDetails) private bondDetails;
    mapping(string => bool) private verifiedIdentities;
    IBondFactory private bondFactory;
    UserDetails public user;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _identityRegistry, address _bondFactoryAddress) external initializer {
        require(_identityRegistry != address(0), "Invalid registry address");

        __Ownable_init();
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

    function createBond(IBond.BondDetails memory _bond) external override returns (bool) {
        address newBond =
            bondFactory.createBond(_bond.asset, _bond.user1, _bond.user2, _bond.user1Amount, _bond.aavePoolAddress);

        bondDetails[newBond] = _bond;
        emit BondDeployed(
            _bond.id,
            _bond.user1,
            _bond.user2,
            _bond.user1Amount,
            _bond.user2Amount,
            _bond.totalBondAmount,
            block.timestamp
        );
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
}
