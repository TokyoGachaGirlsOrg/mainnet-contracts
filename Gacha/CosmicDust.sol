// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CosmicDust is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) public isGachaMachine;

    constructor(address _gachaMachine)
        ERC20("TGG Cosmic Dust", "TGGCosmicDust")
    {
        isGachaMachine[_gachaMachine] = true;
    }

    // function mintDev(address _to, uint256 amount) external onlyOwner {
    //     _mint(_to, amount);
    // }

    // owner sets gacha address
    function setGachaMachine(address _g, bool _tf) external onlyOwner {
        isGachaMachine[_g] = _tf;
    }

    // 0 decimals
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    // gacha machine mints
    function mint(address to, uint256 amount) external onlyGachaMachine {
        _mint(to, amount);
    }

    modifier onlyGachaMachine() {
        require(
            isGachaMachine[msg.sender],
            "Dust: Only gacha machine can mint"
        );
        _;
    }
}
