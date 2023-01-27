// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// the bank allows users to earn ARC over time
// the longer you stay, the more ARC you earn
// this contract handles swappping to and from ARC <> xARC
contract Bank is ERC20, Ownable {
    IERC20 public arc;

    constructor(address _arc) ERC20("TGG xARC", "xARC") {
        arc = IERC20(_arc);
    }

    // enter the bank. deposit arc. earn some shares
    // locks ARC, mints xARC
    function enter(uint256 _amount) public {
        // gets amount of arc locked in bank
        uint256 totalArc = arc.balanceOf(address(this));
        // get amount of xARC in existence
        uint256 totalShares = totalSupply();
        // if no xARC exists, mint 1:1
        if (totalShares == 0 || totalArc == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xARC the ARC is worth.
        // The ratio will change overtime, as xARC is burned/minted
        // and ARC deposited + gained from fees / withdrawn.
        else {
            uint256 what = ((_amount * totalShares) / totalArc);
            _mint(msg.sender, what);
        }
        // lock ARC in contract
        bool success = arc.transferFrom(msg.sender, address(this), _amount);
        require(success, "transfer failed");
    }

    // leave the bank. claim your ARC + rewards
    function leave(uint256 _share) public {
        // gets the amount of xARC in existence
        uint256 totalShares = totalSupply();
        // calculates the amount of ARC the xARC is worth
        uint256 what = (_share * arc.balanceOf(address(this))) / totalShares;
        _burn(msg.sender, _share);
        bool success = arc.transfer(msg.sender, what);
        require(success, "transfer failed");
    }

    function getArcCostForOnexArc() external view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalArc = arc.balanceOf(address(this));
        if (totalShares == 0 || totalArc == 0) {
            return 10**18;
        } else {
            return (totalArc * 10**18) / totalShares;
        }
    }
}
