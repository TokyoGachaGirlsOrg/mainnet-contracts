// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Stats.sol";

// switch to elements 4, 5, and 6 (attuned)

contract CalculateUpgrade is Stats {
    uint256 maxGamerScore = 25;
    uint256 maxCosmicLevel = 10;
    uint256[26] public gsUpgradeCosts = [
        0,
        4,
        4,
        4,
        5,
        5,
        5,
        5,
        5,
        6,
        6,
        7,
        8,
        8,
        8,
        8,
        11,
        11,
        11,
        12,
        12,
        15,
        16,
        16,
        17,
        17
    ];

    uint256[10] public matchedElementCosts = [0, 2, 3, 3, 4, 6, 8, 11, 14, 18];
    uint256[10] public unmatchedElementCosts = [0, 0, 0, 1, 2, 3, 4, 5, 7, 9];

    function calcCosmicLevelUpgradeCost(uint256 id, uint256 toTier)
        public
        view
        returns (uint256[] memory)
    {
        require(toTier <= maxCosmicLevel, "Upgrade: Max cosmic level is 10");
        uint256 currentTier = cosmicLevel[id];
        require(
            currentTier < maxCosmicLevel,
            "Upgrade: cosmic level already max"
        );

        uint256 currentElement = element[id]; // 1 = flame, 2 = terra, 3 = aqua

        uint256[] memory costArray = new uint256[](3);

        uint256 matchedAmount;
        uint256 unmatchedAmount;

        // calc and add required amounts
        for (uint256 i = currentTier + 1; i <= toTier; ++i) {
            matchedAmount += matchedElementCosts[i - 1];
            unmatchedAmount += unmatchedElementCosts[i - 1];
        }

        costArray[currentElement - 1] = matchedAmount;

        for (uint256 j = 0; j < costArray.length; ++j) {
            if (costArray[j] == 0) {
                costArray[j] = unmatchedAmount;
            }
        }

        return costArray;
    }

    function calcGamerScoreUpgradeCost(uint256 id, uint256 toTier)
        public
        view
        returns (uint256)
    {
        require(toTier <= maxGamerScore, "Upgrade: Max score is level 25");
        uint256 gs = gamerScore[id];

        require(gs < maxGamerScore, "Upgrade: Girl already max level");
        uint256 cost;

        for (uint256 i = gs; i <= toTier; i++) {
            cost += gsUpgradeCosts[i];
        }

        return cost;
    }
}
