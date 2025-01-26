//SPDX-License-Identidiier: MIT

pragma solidity 0.8.28;

import "./interfaces/IBond.sol";
import "./interfaces/IUser.sol";
import "./Bond.sol";
import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/IIdentityResolver.sol";

contract User is IUser {

    IIdentityRegistry private immutable identityRegistry;
    mapping(address => IBond.BondDetails) private bondDetails;
    mapping(string => bool) private verifiedIdentities;
    UserDetails public user;

    constructor(address _identityRegistry) {
        require(_identityRegistry != address(0), "Invalid registry address");
        identityRegistry = IIdentityRegistry(_identityRegistry);
        
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
    function createBond(IBond.BondDetails memory _bond) external override returns(bool) {
        //checks
        address newBond = address(new Bond( //will replace bond contract with facotry bond contract
            _bond.id,
            _bond.user1,
            _bond.user2,
            _bond.user1Amount,
            _bond.user2Amount
        ));
        bondDetails[newBond] = _bond;
        emit BondDeployed(_bond.id, _bond.user1, _bond.user2, _bond.user1Amount, _bond.user2Amount, _bond.totalBondAmount, block.timestamp);
        return true;

    }
    function getBondDetails(address _bondAddress) external view returns(IBond.BondDetails memory) {
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