// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesting {
    function payoutVesting() external;
}

contract Rewards is Ownable {
    IERC20 public arc;
    IVesting public vesting;
    address public bankAddress;
    uint256 public arcPerDay = 3424 ether;
    uint256 public faucet = 1 ether;
    // uint256 public lastEmitted = block.timestamp;
    uint256 public lastEmitted = 1674871200;

    constructor(address _vesting) {
        vesting = IVesting(_vesting);
    }

    function sendTokensToBank() public returns (bool complete) {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - lastEmitted;

        if (timePassed > 0) {
            // must be more than 0 seconds
            lastEmitted = currentTime;
            uint256 amount = (timePassed * arcPerDay) / 86400;
            if (arc.balanceOf(address(this)) >= amount) {
                bool success = arc.transfer(bankAddress, amount);
                require(success, "transfer failed");
                return true;
            } else {
                bool success = arc.transfer(
                    bankAddress,
                    arc.balanceOf(address(this))
                );
                require(success, "transfer failed");
                return true;
            }
        }

        return false;
    }

    function setBankAddress(address _bank) external onlyOwner {
        bankAddress = _bank;
    }

    function setArcAddress(address _arc) external onlyOwner {
        arc = IERC20(_arc);
    }

    function setFaucetAmount(uint256 amount) external onlyOwner {
        faucet = amount * 10**18;
    }

    function claimFaucetReward() external {
        uint256 amount = getFaucetRewardAmount();
        if (amount > 0 && sendTokensToBank()) {
            vesting.payoutVesting();
            bool success = arc.transfer(msg.sender, amount);
            require(success, "transfer failed");
        }
    }

    function getFaucetRewardAmount() public view returns (uint256 amount) {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - lastEmitted;
        if (timePassed > 0) {
            amount = (faucet * timePassed) / 86400;
        } else {
            amount = 0;
        }
    }
}
