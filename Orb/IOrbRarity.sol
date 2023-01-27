// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IOrbRarity {
    function setRarity(uint256 amount) external;

    function getRarity(uint256 token) external view returns (uint256);

    function getRarityString(uint256 token)
        external
        view
        returns (string memory);

    function getAllRarities() external view returns (uint256[] memory);
}
