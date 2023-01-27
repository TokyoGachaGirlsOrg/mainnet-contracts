// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Orb/IOrbRarity.sol";
import "./Stats.sol";

contract Whitelist is Ownable {
    IERC721 public orb;
    IOrbRarity public orbRarity;

    uint256 cost;
    uint256 discountPerc = 90;
    uint256 public charges = 5;
    uint256 private devFee = 6;

    mapping(uint256 => uint256) public chargesUsed;

    function queueCharge(uint256 id) internal returns (uint256) {
        // take charge
        require(chargesUsed[id] < 5, "Girl: out of charges");
        ++chargesUsed[id];
        // queue charge
        uint256 rarity = 6;

        if (chargesUsed[id] == 5) {
            // return max rarity
            rarity = orbRarity.getRarity(id);
        }

        return rarity;
    }

    function getChargesRemaining(uint256 id) public view returns (uint256) {
        return charges - chargesUsed[id];
    }

    function setCost(uint256 _newCost) public onlyOwner {
        require(_newCost > 0, "Girl: cost cant be 0");
        cost = _newCost;
    }

    function getCost() public view returns (uint256) {
        return cost;
    }

    function getDiscountCost() public view returns (uint256) {
        return (cost * discountPerc) / 100;
    }

    function getDevFee(uint256 _cost) public view returns (uint256) {
        return (_cost * devFee) / 100;
    }

    function setDevFee(uint256 _fee) external onlyOwner {
        devFee = _fee;
    }
}
