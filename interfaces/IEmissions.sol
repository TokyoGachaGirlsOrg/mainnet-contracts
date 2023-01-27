// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEmissions {
    function updateTotalRewardsPerDay(
        uint256 girlId,
        uint256 oldGs,
        uint256 oldCl
    ) external;

    function claimBeforeUpgrade(uint256 id) external;

    function newGirl(uint256 id) external;
}
