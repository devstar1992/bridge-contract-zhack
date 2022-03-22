// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.11;

interface IStakingV1 {
    function unstake(uint256 _amount, bool _trigger) external;

    function index() external view returns (uint256);
}
