// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

contract Owner {
    address public immutable s_owner;
    uint public s_amount;
    uint public s_maxAmountCanWithdraw;

    constructor(address _owner, uint _amount, uint _maxWithdrawable) {
        s_owner = _owner;
        s_amount = _amount;
        s_maxAmountCanWithdraw = _maxWithdrawable;
    }

    function transferToOwner(uint256 amount) public {
        require(msg.sender == s_owner, "NOT_OWNER");
        require(amount > 0, "POSITIVE_AMOUNT");
        require(amount <= s_maxAmountCanWithdraw, "INVALID_AMOUNT");
        (bool success, ) = payable(s_owner).call{value: amount}("");
        unchecked {
            s_maxAmountCanWithdraw = s_maxAmountCanWithdraw - amount;
        }
        require(success, "TRANSFER_FAILED");
    }

    function setAmount(uint256 _amount) public {
        require(msg.sender == s_owner, "Not owner");
        require(_amount > 0, "POSITIVE_AMOUNT");

        s_amount = _amount;
    }
}
