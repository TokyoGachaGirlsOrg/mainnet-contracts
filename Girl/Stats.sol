// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Stats is Ownable {
    event CosmicLevelChanged(uint256 id, uint256 newLevel);
    event GamerScoreChanged(uint256 id, uint256 newScore);
    event ElementChanged(uint256 id, uint256 element);

    mapping(uint256 => uint256) public cosmicLevel;
    mapping(uint256 => uint256) public gamerScore;
    mapping(uint256 => uint256) public element;

    // only girl
    function _initStats(
        uint256 id,
        uint256 cl,
        uint256 el
    ) internal returns (uint256, uint256) {
        cosmicLevel[id] = cl;
        element[id] = el;
        return (cl, el);
    }

    function _upgradeCosmicLevel(uint256 _id, uint256 _newCosmicLevel)
        internal
    {
        cosmicLevel[_id] = _newCosmicLevel;
        emit CosmicLevelChanged(_id, _newCosmicLevel);
    }

    function _upgradeGamerScore(uint256 _id, uint256 _newGamerScore) internal {
        gamerScore[_id] = _newGamerScore;
        emit GamerScoreChanged(_id, _newGamerScore);
    }

    function setElement(uint256 _id, uint256 _newElement) external onlyOwner {
        element[_id] = _newElement;
        emit ElementChanged(_id, _newElement);
    }

    function getCosmicLevel(uint256 _id) public view returns (uint256) {
        return cosmicLevel[_id];
    }

    function getGamerScore(uint256 _id) public view returns (uint256) {
        return gamerScore[_id];
    }

    function getElement(uint256 _id) public view returns (uint256) {
        return element[_id];
    }
}
