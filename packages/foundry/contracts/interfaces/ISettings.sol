//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

interface ISettings {
    /*
    --------------------------
    ----------ERRORS----------
    --------------------------
    */

    /*
    --------------------------
    ----------EVENTS----------
    --------------------------
    */
    event ProtocolFeeChanged(uint256 oldFee, uint256 newFee);

    /*
    --------------------------
    ----------FUNCTIONS----------
    --------------------------
    */
    function getProtocolFee() external view returns (uint256);
    function setProtocolFee(uint256 _fee) external returns (bool);
}
