// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.4;

contract OrbRarity is Ownable {
    mapping(uint256 => uint256) private allowance;
    mapping(uint256 => string) rarityString;

    uint256[] public rarity;

    string public secret;

    uint256 countFrom = 0;
    uint256 randomCounter = 0;
    uint256 public batchSize = 25;

    constructor(string memory _secret) {
        // allowance[0] = 0; // 1 moon
        allowance[1] = 525; // 2 star
        allowance[2] = 325; // 3 galaxy
        allowance[3] = 113; // 4 astral
        allowance[4] = 37; // 5 celestial

        // rarityString[0] = "Moon";
        rarityString[1] = "Star";
        rarityString[2] = "Galaxy";
        rarityString[3] = "Astral";
        rarityString[4] = "Celestial";

        secret = _secret;
    }

    function setRarity() external onlyOwner {
        uint256 countTo = countFrom + batchSize;
        // make sure not sold out
        for (uint256 i = countFrom; i < countTo; ++i) {
            require(
                allowance[1] >= 1 ||
                    allowance[2] >= 1 ||
                    allowance[3] >= 1 ||
                    allowance[4] >= 1,
                "complete"
            );

            // create random num that is allowed
            uint256 num = _random();
            while (allowance[num] < 1) {
                num++;
                if (num > 4) {
                    num -= 4;
                }
            }

            // update state
            rarity.push(num);
            allowance[num]--;
            randomCounter++;
        }
        countFrom += batchSize;
    }

    function getRarity(uint256 token) external view returns (uint256) {
        return rarity[token - 1] + 1;
    }

    function getRarityString(uint256 token)
        external
        view
        returns (string memory)
    {
        return rarityString[rarity[token - 1]];
    }

    function getAllRarities() external view returns (uint256[] memory) {
        return rarity;
    }

    function _random() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(randomCounter, secret))
        );
        return (randomNumber % 4) + 1;
    }
}
