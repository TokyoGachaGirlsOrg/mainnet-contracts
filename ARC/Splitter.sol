// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Splitter is Ownable {
    mapping(uint256 => address) public payeeAddress;
    mapping(uint256 => uint256) public payeePerc;
    uint256 public payees = 4;

    function setInitialPayees(
        address _a,
        address _b,
        address _c,
        address _d,
        uint256 _aPerc,
        uint256 _bPerc,
        uint256 _cPerc,
        uint256 _dPerc
    ) external onlyOwner {
        setPayee(0, _a, _aPerc);
        setPayee(1, _b, _bPerc);
        setPayee(2, _c, _cPerc);
        setPayee(3, _d, _dPerc);
    }

    function _getAmount(uint256 amount, uint256 _id)
        internal
        view
        returns (uint256)
    {
        return (amount * payeePerc[_id]) / 100;
    }

    function setPayee(
        uint256 _id,
        address _addr,
        uint256 _perc
    ) public onlyOwner {
        payeeAddress[_id] = _addr;
        payeePerc[_id] = _perc;
    }

    function setPayeesLength(uint256 _l) external onlyOwner {
        payees = _l;
    }
}
