// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.11;

import "./IERC20.sol";

// Old wsACRN interface
interface IwsACRN is IERC20 {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wACRNTosACRN(uint256 _amount) external view returns (uint256);

    function sACRNTowACRN(uint256 _amount) external view returns (uint256);
}
