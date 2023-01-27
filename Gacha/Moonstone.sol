// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGirl.sol";

// moonstones upgrade girl gamer score
contract Moonstone is ERC20, ERC20Burnable, Ownable {
    IGirl public girlContract;

    mapping(address => bool) public isGachaMachine; // only gacha can mint

    event GamerScoreUpgraded(uint256 id, uint256 toTier);

    constructor(address _gachaMachine, address _girlContract)
        ERC20("TGG Moonstone", "TGGMoonstone")
    {
        // give permissions and set interface
        setGachaMachine(_gachaMachine, true);
        setGirlContract(_girlContract);
    }

    // function mintDev(address _to, uint256 amount) external onlyOwner {
    //     _mint(_to, amount);
    // }

    function mint(address to, uint256 amount) external onlyGachaMachine {
        _mint(to, amount);
    }

    function upgradeGamerScore(uint256 id, uint256 toTier) external {
        // get cost
        uint256 cost = girlContract.getGamerScoreUpgradeCost(id, toTier);

        // check that cost is not 0 and user has enough tokens
        require(cost > 0, "Upgrade: cost == 0");
        require(balanceOf(msg.sender) >= cost, "Moonstone: not enough tokens");

        // check owner of girl
        require(
            girlContract.ownerOf(id) == msg.sender,
            "Moonstone: upgrade caller not owner"
        );

        // burn amount
        burn(cost);

        // upgrade stats
        girlContract.handleUpgradeGamerScore(id, toTier);

        emit GamerScoreUpgraded(id, toTier);
    }

    function setGirlContract(address _girlContract) public onlyOwner {
        girlContract = IGirl(_girlContract);
    }

    function setGachaMachine(address _g, bool _tf) public onlyOwner {
        isGachaMachine[_g] = _tf;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    modifier onlyGachaMachine() {
        require(
            isGachaMachine[msg.sender],
            "Moonstone: Only gacha machine can mint"
        );
        _;
    }
}
