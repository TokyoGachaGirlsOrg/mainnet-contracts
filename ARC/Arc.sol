// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Splitter.sol";

interface IGacha {
    function spin(address user, uint256 amount)
        external
        returns (string[] memory);

    function getCost() external view returns (uint256);
}

contract Arc is ERC20, ERC20Burnable, Splitter {
    IERC721 public girls;
    IGacha public gacha;
    address public rewards;

    mapping(address => bool) public isWhitelisted;

    address public emissions;

    uint256 public maxSupply = 50000000 ether;
    uint256 public spinId;
    uint256 public maxSpins = 100;

    event GachaSpun(
        address indexed user,
        address indexed gachaAddress,
        uint256 indexed spinId,
        uint256 amount
    );

    constructor(
        address _emissions,
        address _rewards,
        address _vesting
    ) ERC20("TGG ARC", "ARC") {
        setEmissionsContract(_emissions);
        setBankRewardsContract(_rewards);

        _mint(msg.sender, 2437500 * 10**decimals()); // 1 mil to LP/1 mil to Phase 2/seed
        _mint(emissions, 34710000 * 10**decimals()); // to emissions contract
        _mint(_rewards, 2500000 * 10**decimals()); // bank rewards
        _mint(_vesting, 10352500 * 10**decimals()); // to vesting contract
    }

    // function mintDev(address _to, uint256 amount) external onlyOwner {
    //     _mint(_to, amount);
    // }

    function setEmissionsContract(address _emissions) public onlyOwner {
        emissions = _emissions;
    }

    function setBankRewardsContract(address _rewards) public onlyOwner {
        rewards = _rewards;
    }

    // ecosystem functionality
    function _split(uint256 amount) internal {
        uint256 amountRemainingAfterSplit = amount;
        for (uint256 i = 0; i < payees; ++i) {
            uint256 amountTracker = _getAmount(amount, i);
            transfer(payeeAddress[i], amountTracker);
            amountRemainingAfterSplit -= amountTracker;
        }
        burn(amountRemainingAfterSplit);
    }

    function setGirlContract(address _girlContractAddress) public onlyOwner {
        girls = IERC721(_girlContractAddress);
    }

    function setMaxSpins(uint256 _maxSpins) external onlyOwner {
        maxSpins = _maxSpins;
    }

    function spinGacha(address _gachaAddress, uint256 _amount) public {
        require(isWhitelisted[_gachaAddress], "Spender: Gacha not whitelisted");
        require(
            _amount >= 1 && _amount <= maxSpins,
            "Spender: spin 1 to maxSpins times"
        );
        gacha = IGacha(_gachaAddress);
        uint256 cost = (gacha.getCost() * _amount);
        require(balanceOf(msg.sender) >= cost, "Spender: user not enough ARC");
        _split(cost);

        spinId++;

        // emit event for backend
        emit GachaSpun(msg.sender, _gachaAddress, spinId, _amount);
    }

    function addWhitelist(address _a) public onlyOwner {
        isWhitelisted[_a] = true;
    }

    function getIsWhitelisted(address _a) external view returns (bool) {
        return isWhitelisted[_a];
    }

    function removeWhitelist(address _a) public onlyOwner {
        isWhitelisted[_a] = false;
    }
}
