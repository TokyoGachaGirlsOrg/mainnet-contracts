// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IGirl.sol";
import "../interfaces/IElementalStone.sol";

contract Attunement is ERC1155Holder, ReentrancyGuard, Ownable {
    IElementalStone public elementalStone;

    IGirl public girl;
    uint256 public defaultTimeRequired = 7 days;
    uint256 public matchedTimeRequired = defaultTimeRequired / 2;
    uint256 public globalDepID;

    struct Deposit {
        address owner;
        uint256 depositId;
        uint256 element;
        uint256 girlId;
        uint256 timeDeposited;
        bool matched;
        uint256 unlockTime;
    }

    Deposit[] public deposits;

    mapping(address => uint256[]) public usersDepositIds;
    // gives back depositID by girlID
    mapping(uint256 => uint256) public depositByGirlID;

    constructor(address _elemental, address _girl) {
        elementalStone = IElementalStone(_elemental);
        girl = IGirl(_girl);
    }

    function getUserDepositIds(address _user)
        public
        view
        returns (uint256[] memory)
    {
        // filter out 0s
        uint256 active = 0;

        for (uint256 i = 0; i < usersDepositIds[_user].length; ++i) {
            if (usersDepositIds[_user][i] != 0) {
                ++active;
            }
        }

        uint256[] memory cleanedIds = new uint256[](active);

        uint256 index = 0;

        for (uint256 i = 0; i < usersDepositIds[_user].length; ++i) {
            uint256 num = usersDepositIds[_user][i];
            if (num != 0) {
                cleanedIds[index] = num;
                ++index;
            }
        }

        return cleanedIds;
    }

    function getUserActiveDeposits(address _user)
        external
        view
        returns (Deposit[] memory)
    {
        uint256[] memory ids = getUserDepositIds(_user);
        Deposit[] memory activeDeposits = new Deposit[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            activeDeposits[i] = deposits[ids[i] - 1];
        }

        return activeDeposits;
    }

    function cancelStake(uint256 depositId) external nonReentrant {
        address user = deposits[depositId - 1].owner;
        require(msg.sender == user, "Attunement: caller not owner");
        uint256 stoneID = deposits[depositId - 1].element;
        bool success = _returnStone(user, stoneID);
        require(success);
        _removeDeposit(depositId);
    }

    function _returnStone(address _user, uint256 _stoneID)
        internal
        returns (bool)
    {
        IERC1155 stone = IERC1155(address(elementalStone));
        stone.safeTransferFrom(address(this), _user, _stoneID, 1, "");
        return true;
    }

    function girlTransferred(uint256 girlID) external onlyGirl nonReentrant {
        if (girl.isPaired(girlID)) {
            uint256 depositID = depositByGirlID[girlID];
            address user = deposits[depositID - 1].owner;
            uint256 stoneID = deposits[depositID - 1].element;
            bool success = _returnStone(user, stoneID);
            require(success);
            _removeDeposit(depositID);
        }
    }

    function _removeDeposit(uint256 _depositId) internal {
        Deposit memory deposit = deposits[_depositId - 1];
        uint256 girlID = deposit.girlId;
        address _user = deposit.owner;
        for (uint256 i = 0; i < usersDepositIds[_user].length; ++i) {
            if (usersDepositIds[_user][i] == _depositId) {
                delete usersDepositIds[_user][i];
                break;
            }
        }
        delete deposits[_depositId - 1];
        delete depositByGirlID[girlID];
        // remove isPaired
        girl.setPaired(girlID, false);
    }

    // deposits array access = globalDepID - 1

    function stake(
        address user,
        uint256 id,
        uint256 girlId,
        bool isMatched
    ) external onlyElementalStone {
        uint256 currentTime = block.timestamp;
        uint256 unlockTime;

        if (isMatched) {
            unlockTime = currentTime + matchedTimeRequired;
        } else {
            unlockTime = currentTime + defaultTimeRequired;
        }

        ++globalDepID;
        deposits.push(
            Deposit(
                user,
                globalDepID,
                id,
                girlId,
                currentTime,
                isMatched,
                unlockTime
            )
        );
        usersDepositIds[user].push(globalDepID);
        depositByGirlID[girlId] = globalDepID;
    }

    function attune(uint256 depositId) external nonReentrant returns (bool) {
        uint256 depositIndex = depositId - 1;
        require(
            deposits[depositIndex].owner == msg.sender,
            "Attunement: caller not owner"
        );
        require(_isReadyForAttunement(depositIndex), "Attunement: not ready");

        elementalStone.attune(
            msg.sender,
            deposits[depositIndex].element,
            deposits[depositIndex].girlId
        );
        _removeDeposit(depositId);
        return true;
    }

    function _isReadyForAttunement(uint256 depositId)
        internal
        view
        returns (bool ready)
    {
        if (deposits[depositId].unlockTime <= block.timestamp) {
            return true;
        }
        return false;
    }

    function isComplete(uint256 depositId) external view returns (bool) {
        return _isReadyForAttunement(depositId - 1);
    }

    function getUnlockTime(uint256 depositId)
        external
        view
        returns (uint256 unlockTime)
    {
        return deposits[depositId - 1].unlockTime;
    }

    modifier onlyElementalStone() {
        require(
            msg.sender == address(elementalStone),
            "Attunement: only ES contract can call"
        );
        _;
    }

    modifier onlyGirl() {
        require(msg.sender == address(girl), "Attunement: only girl can call");
        _;
    }
}
