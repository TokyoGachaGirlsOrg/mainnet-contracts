// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGirl {
    function getCosmicLevel(uint256 _id) external view returns (uint256);

    function getGamerScore(uint256 _id) external view returns (uint256);

    function isPaired(uint256 girlId) external view returns (bool);

    function setPaired(uint256 _id, bool _paired) external;

    function checkStake(uint256 girlId)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function getCosmicLevelUpgradeCost(uint256 id, uint256 toTier)
        external
        view
        returns (uint256[] memory);

    function handleUpgradeCosmicLevel(uint256 id, uint256 toTier) external;

    function getGamerScoreUpgradeCost(uint256 id, uint256 toTier)
        external
        view
        returns (uint256 cost);

    function handleUpgradeGamerScore(uint256 id, uint256 toTier) external;

    function ownerOf(uint256 id) external view returns (address);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}
