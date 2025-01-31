//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./interfaces/IBondFactory.sol";
import "./interfaces/IUser.sol";
import "./Bond.sol";
import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/IIdentityResolver.sol";

import "./interfaces/IFeeSettings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract User is IUser {
    mapping(address => IBond.BondDetails) private bondDetails;
    mapping(string => bool) private verifiedIdentities;

    UserDetails public user;

    IIdentityRegistry private identityRegistry;
    IFeeSettings private feeSettings;

    mapping(string => string) slashingWords;

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
    address _aavePoolAddress,
    address _uiPoolDataAddress,
    address _ypsFactoryAddress,
    address _bondFactoryAddress
  ) public payable returns (bool) {
    feeSettings.collectFees{value: msg.value}(msg.sender, msg.value, msg.sig);

    IBondFactory bondFactory = IBondFactory(_bondFactoryAddress);
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

    function createBond(
        IBond.BondDetails memory _bond,
        address _aavePoolAddress,
        address _uiPoolDataAddress,
        address _ypsFactoryAddress
    ) external override returns (bool) { }
}
