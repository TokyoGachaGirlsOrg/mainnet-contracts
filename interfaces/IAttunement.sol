// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAttunement {
    function stake(
        address user,
        uint256 id,
        uint256 girlId,
        bool isMatched
    ) external;

    function attune(
        address _account,
        uint256 _id,
        uint256 _girlId
    ) external;

    function girlTransferred(uint256 girlID) external;
}
