// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IGirl.sol";

contract Emissions is Ownable {
    // interfaces
    IERC20 public arc; // payout token
    IGirl public girl; // nft that earns and claims
    // uint
    uint256 public base = 1 ether; // base and inc help calc rewards per day
    uint256 public inc = 0.5 ether; // based on cosmic level and gamer score
    // uint256 public startTime = block.timestamp;
    uint256 public startTime = 1674871200; // time at which emissions start
    uint256 public lastTimeStepUpdated = startTime; // helps keep track of time passed since update
    uint256 public stepSupply = 3471000 ether; // amount of tokens til reward ratio decrease
    uint256 ratioDiv = 10000000; // helps with math => amount * (ratio[i] / ratioDiv) gives percent
    uint256 lastStep = 10; // rewards dont decrease after stepTimeStamps[10]
    uint256 public totalRewardsPerDay; // eco total payout per day - does not account for ratio
    // mapping
    mapping(uint256 => Receipt) public receipt; // stores girl claim info
    mapping(uint256 => uint256) public stepTimeStamps; // predicted time stamps at reward decrease 1-10
    // math arrays
    uint256[] public multiplier = [0, 100, 125, 150, 175, 200];
    uint256[] ratio = [
        0,
        10000000,
        8209150,
        6659170,
        5261950,
        4021030,
        2940610,
        2025820,
        1283170,
        721510,
        354340
    ];

    // struct keeps track of when the last time user claimed
    struct Receipt {
        uint256 timeLastClaimed;
        uint256 stepLastClaimed;
    }

    // returns current rewards ratio index
    function _getCurrentStep(uint256 time)
        internal
        view
        returns (uint256 step)
    {
        if (block.timestamp <= startTime || stepTimeStamps[1] == 0) {
            return 1;
        }
        // if none mint by start time return step 1
        // if (time >= stepTimeStamps[lastStep]) return 10; // handle ending case
        else {
            for (uint256 i = 1; i <= lastStep; ++i) {
                if (time < stepTimeStamps[i] && time > stepTimeStamps[i - 1]) {
                    return i;
                }
            }
        }
    }

    // returns the timestamp in seconds at which rewards decrease
    function getPredictedTimeStamps(uint256 index)
        external
        view
        returns (uint256 time)
    {
        return stepTimeStamps[index];
    }

    // external functions
    // claim function for use on upgrade
    function claimBeforeUpgrade(uint256 girlId) external onlyGirl {
        _claim(girlId);
    }

    // once emissions are deployed, when a girl is minted this function should
    // be called with girl NFT token ID
    function newGirl(uint256 id) external onlyGirl {
        uint256 time = block.timestamp;

        totalRewardsPerDay +=
            (multiplier[girl.getCosmicLevel(id)] * 10**18) /
            100;

        uint256 currentStep = _getCurrentStep(time);
        if (time >= startTime) {
            // minted after emissions start
            receipt[id] = Receipt(time, currentStep);
            _setStepTimeStamps(currentStep, time);
        } else {
            // minted before emissions start
            receipt[id] = Receipt(startTime, currentStep);
            _setStepTimeStamps(currentStep, startTime);
        }
    }

    // updating total rewards per seconds updates predicted ratio change
    // time stamps on upgrade
    function updateTotalRewardsPerDay(
        uint256 girlId,
        uint256 oldGs,
        uint256 oldCl
    ) external onlyGirl {
        // get old rate
        // add new rate - old rate to total
        uint256 difference = _getBaseDailyEmissions(girlId) -
            _oldRatePerDay(oldGs, oldCl);
        totalRewardsPerDay += difference;
        uint256 time = block.timestamp;
        _setStepTimeStamps(_getCurrentStep(time), time);
    }

    // internal functions

    function _claim(uint256 girlId) internal {
        uint256 currentTime = block.timestamp;
        uint256 currentStep = _getCurrentStep(currentTime);

        // calc reward
        uint256 reward = _sumOwed(girlId, currentTime);

        // update receipt
        receipt[girlId] = Receipt(currentTime, currentStep);

        // send tokens
        bool success = arc.transfer(girl.ownerOf(girlId), reward);
        require(success, "transfer failed");
    }

    // internal function calculates amount owed
    function _sumOwed(uint256 girlId, uint256 currentTime)
        internal
        view
        returns (uint256 sum)
    {
        uint256 time = block.timestamp;
        if (time <= startTime) {
            return 0;
        }
        uint256 currentStep = _getCurrentStep(time);
        uint256 newLastClaimed = receipt[girlId].timeLastClaimed;
        uint256 basePerSec = _getBaseRewardPerSecond(girlId);
        for (
            uint256 i = receipt[girlId].stepLastClaimed;
            i <= currentStep;
            ++i
        ) {
            uint256 secondsPassedForStep;

            // if on different step than last claimed
            // claim the full step - timeLastClaimed
            if (currentTime >= stepTimeStamps[i]) {
                // claim all the seconds for that step minus the last time claimed
                secondsPassedForStep = stepTimeStamps[i] - newLastClaimed;
                // set last claimed to the previous steps max
                newLastClaimed = stepTimeStamps[i];
            } else {
                // claiming on current step pays now - last claimed
                secondsPassedForStep = currentTime - newLastClaimed;
            }

            sum += (basePerSec * ratio[i] * secondsPassedForStep) / ratioDiv;
        }
    }

    // internal calc
    function _getBaseDailyEmissions(uint256 _id)
        internal
        view
        returns (uint256 emissions)
    {
        uint256 cosmicLevel = girl.getCosmicLevel(_id);
        uint256 gamerScore = girl.getGamerScore(_id);

        uint256 calculateMx;
        uint256 calculateGse = gamerScore * inc;

        if (cosmicLevel >= 5) {
            calculateMx = multiplier[5];
        } else {
            calculateMx = multiplier[cosmicLevel];
        }

        return ((base + calculateGse) * calculateMx) / 100;
    }

    function _getBaseRewardPerSecond(uint256 _id)
        internal
        view
        returns (uint256)
    {
        return _getBaseDailyEmissions(_id) / 86400;
    }

    // set predicted ratio change timestamps
    function _setStepTimeStamps(uint256 index, uint256 time) internal {
        uint256 timePassed = 0;

        if (time > startTime) {
            timePassed = time - lastTimeStepUpdated;
            lastTimeStepUpdated = time;
        }

        for (uint256 i = index; i <= lastStep; ++i) {
            if (i == 1) {
                // first step
                stepTimeStamps[i] = _calcTimestamp(i) + timePassed + startTime;
            } else if (i > 1 && i == index) {
                // current step
                stepTimeStamps[i] = _calcTimestamp(i) + timePassed;
            } else if (i > index) {
                // future step
                stepTimeStamps[i] = _calcTimestamp(i);
            }
        }
    }

    // how much time it takes to drain 10% of supply
    function _calcTimestamp(uint256 i) internal view returns (uint256 num) {
        num =
            ((stepSupply * ratioDiv * 86400) /
                (totalRewardsPerDay * ratio[i])) +
            stepTimeStamps[i - 1];
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function _oldRatePerDay(uint256 gs, uint256 cl)
        internal
        view
        returns (uint256 oldRate)
    {
        uint256 calculateMx;
        uint256 calculateGse = gs * inc;

        if (cl >= 5) {
            calculateMx = multiplier[5];
        } else {
            calculateMx = multiplier[cl];
        }

        return (((base + calculateGse) * calculateMx) / 100);
    }

    // for front end

    // claim owed tokens
    function claim(uint256 girlId) public {
        require(
            msg.sender == girl.ownerOf(girlId),
            "Emissions: caller not owner of ID"
        );
        _claim(girlId);
    }

    function claimAll(uint256[] calldata ids) external {
        uint256 len = ids.length;
        for (uint256 i = 0; i < len; ++i) {
            claim(ids[i]);
        }
    }

    function getSumOwed(uint256 girlId) external view returns (uint256 sum) {
        return _sumOwed(girlId, block.timestamp);
    }

    function getTotalSumOwed(uint256[] calldata ids)
        external
        view
        returns (uint256 sum)
    {
        uint256 len = ids.length;
        uint256 time = block.timestamp;
        for (uint256 i = 0; i < len; ++i) {
            sum += _sumOwed(ids[i], time);
        }
    }

    function getDailyWithRatio(uint256 girlId)
        external
        view
        returns (uint256 daily)
    {
        daily =
            (_getBaseDailyEmissions(girlId) *
                ratio[_getCurrentStep(block.timestamp)]) /
            ratioDiv;
    }

    function getCurrentStep() external view returns (uint256 step) {
        return _getCurrentStep(block.timestamp);
    }

    // constructor functions
    function setGirlContract(address _girl) public onlyOwner {
        girl = IGirl(_girl);
    }

    function setArcContract(address _a) public onlyOwner {
        arc = IERC20(_a);
    }

    // modifiers
    modifier onlyGirl() {
        require(msg.sender == address(girl), "Emissions: only girl can call");
        _;
    }
}
