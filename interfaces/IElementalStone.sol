// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IElementalStone {
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function attune(
        address account,
        uint256 id,
        uint256 girlId
    ) external;
}
