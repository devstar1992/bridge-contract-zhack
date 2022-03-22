// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.11;

import "../interfaces/IERC20.sol";
import "../types/Ownable.sol";

contract AcrnFaucet is Ownable {
    IERC20 public acrn;

    constructor(address _acrn) {
        acrn = IERC20(_acrn);
    }

    function setAcrn(address _acrn) external onlyOwner {
        acrn = IERC20(_acrn);
    }

    function dispense() external {
        acrn.transfer(msg.sender, 1e9);
    }
}
