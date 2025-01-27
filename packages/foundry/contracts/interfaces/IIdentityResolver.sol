// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IIdentityResolver {
    function verify(bytes calldata data) external view returns (bool);
}
