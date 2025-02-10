// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IBondFactory {
    function createBond(address _asset, address _user1, address _user2, address _yieldProviderServiceAddress)
        external
        returns (address);
}
