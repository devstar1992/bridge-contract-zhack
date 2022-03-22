// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.11;

interface IAllocator {
    // Should have deposit/withdraw methods (interfaces aren't standardized)
    function harvest() external;
}
