// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting is Ownable {
    IERC20 public arc;

    address public devOps; // 7,915,000 // 10842
    address public team; // 2,000,000 // 2740
    // address public seed; // 437,500   // 2430

    uint256 public devOpsPerDay = 10842 ether;
    uint256 public teamPerDay = 2739 ether;
    uint256 public seedPerDay = 2430 ether;

    uint256 public startTime = 1674871200;
    uint256 public seedStartTime = startTime + 7 days;
    uint256 public devLastClaimed = startTime;
    uint256 public seedLastClaimed = seedStartTime;

    uint256 public devMaxDays = startTime + 730 days;
    uint256 public seedMaxDays = seedStartTime + 180 days;

    mapping(uint256 => address) public seeders;
    uint256 seedersCount;

    function payoutVesting() external {
        payoutDev();
        payoutSeed();
    }

    function payoutDev() public {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - devLastClaimed;

        if (currentTime > devMaxDays) {
            timePassed = devMaxDays - devLastClaimed;
            if (timePassed > 0) {
                devLastClaimed = devMaxDays;
                bool success = arc.transfer(
                    devOps,
                    (timePassed * devOpsPerDay) / 86400
                );
                require(success, "transfer failed");
                bool success2 = arc.transfer(
                    team,
                    (timePassed * teamPerDay) / 86400
                );
                require(success2, "transfer failed");
            }
        } else {
            devLastClaimed = currentTime;
            bool success = arc.transfer(
                devOps,
                (timePassed * devOpsPerDay) / 86400
            );
            require(success, "transfer failed");
            bool success2 = arc.transfer(
                team,
                (timePassed * teamPerDay) / 86400
            );
            require(success2, "transfer failed");
        }
    }

    function payoutSeed() public {
        uint256 currentTime = block.timestamp;
        if (currentTime > seedStartTime) {
            uint256 timePassed = currentTime - seedLastClaimed;
            if (currentTime > seedMaxDays) {
                timePassed = seedMaxDays - seedLastClaimed;
                if (timePassed > 0) {
                    seedLastClaimed = seedMaxDays;
                    for (uint256 i = 0; i < seedersCount; ++i) {
                        bool success = arc.transfer(
                            seeders[i],
                            // (timePassed * (seedPerDay / seedersCount)) / 86400
                            ((timePassed * seedPerDay) / seedersCount) / 86400
                        );
                        require(success, "transfer failed");
                    }
                }
            } else {
                seedLastClaimed = currentTime;
                for (uint256 i = 0; i < seedersCount; ++i) {
                    bool success = arc.transfer(
                        seeders[i],
                        // (timePassed * (seedPerDay / seedersCount)) / 86400
                        ((timePassed * seedPerDay) / seedersCount) / 86400
                    );
                    require(success, "transfer failed");
                }
            }
        }
    }

    function addSeeder(address _seeder) public onlyOwner {
        seeders[seedersCount] = _seeder;
        seedersCount++;
    }

    function removeSeed(uint256 index) public onlyOwner {
        delete seeders[index];
        seedersCount--;
    }

    function viewSeeder(uint256 index) public view returns (address) {
        return seeders[index];
    }

    function setDevOps(address _d) external onlyOwner {
        devOps = _d;
    }

    function setArc(address _arc) external onlyOwner {
        arc = IERC20(_arc);
    }

    function setTeam(address _t) external onlyOwner {
        team = _t;
    }
}
