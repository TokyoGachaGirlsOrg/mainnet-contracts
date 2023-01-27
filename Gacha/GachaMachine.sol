// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IElementalStone.sol";

interface IMoonstone {
    function mint(address to, uint256 amount) external;
}

interface ICosmicDust {
    function mint(address to, uint256 amount) external;
}

contract GachaMachine is Ownable {
    IMoonstone public moonstone;
    ICosmicDust public cosmicDust;
    IElementalStone public elementalStone;

    mapping(address => bool) public isArc;
    mapping(address => bool) public isWorker;

    uint256 public costPerSpin = 10 ether;

    event DealerSent(address indexed user, uint256 indexed spinId);

    constructor(address _arc) {
        isArc[_arc] = true;
        setWorker(msg.sender, true);
    }

    function setMoonstone(address _a) public onlyOwner {
        moonstone = IMoonstone(_a);
    }

    function setCosmicDust(address _a) public onlyOwner {
        cosmicDust = ICosmicDust(_a);
    }

    function setElementalStone(address _a) public onlyOwner {
        elementalStone = IElementalStone(_a);
    }

    function dealerSend(
        address user,
        uint256 spinId,
        uint256 cosmicDustAmount,
        uint256 moonstoneAmount,
        uint256 flameAmount,
        uint256 terraAmount,
        uint256 aquaAmount
    ) external onlyWorker {
        cosmicDust.mint(user, cosmicDustAmount);

        if (moonstoneAmount > 0) {
            moonstone.mint(user, moonstoneAmount);
        }

        if (flameAmount > 0) {
            elementalStone.mint(user, 1, flameAmount);
        }

        if (terraAmount > 0) {
            elementalStone.mint(user, 2, terraAmount);
        }

        if (aquaAmount > 0) {
            elementalStone.mint(user, 3, aquaAmount);
        }

        emit DealerSent(user, spinId);
    }

    function getCost() external view returns (uint256) {
        return costPerSpin;
    }

    function setCost(uint256 _c) public onlyOwner {
        costPerSpin = _c;
    }

    function setWorker(address _worker, bool _isWorker) public onlyOwner {
        isWorker[_worker] = _isWorker;
    }

    modifier onlyWorker() {
        require(isWorker[msg.sender], "Gacha: only worker can call");
        _;
    }
}
