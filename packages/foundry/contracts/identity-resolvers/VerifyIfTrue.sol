// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IIdentityResolver } from "../interfaces/IIdentityResolver.sol";

contract VerifyIfTrue is IIdentityResolver {
    struct VerificationData {
        bool shouldVerify;
    }

    function verify(bytes calldata data) external view override returns (bool) {
        VerificationData memory verificationData = abi.decode(data, (VerificationData));
        return verificationData.shouldVerify;
    }
}
