// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

contract Owner {
    address public s_owner;
    uint public s_amount;
    uint public s_maxAmountCanWithdraw;

    constructor(address _owner, uint _amount, uint _maxWithdrawable) {
        s_owner = _owner;
        s_amount = _amount;
        s_maxAmountCanWithdraw = _maxWithdrawable;
    }

    function transferToOwner(uint256 amount) public {
        require(msg.sender == s_owner, "Only onwer can withdraw");
        require(amount > 0, "Amount cannot be 0.");
        require(
            amount <= s_maxAmountCanWithdraw,
            "Amount cannot be greater than maximum withdrawable amount."
        );
        (bool success, ) = payable(s_owner).call{value: amount}("");
        require(success, "Payment Failed.");
    }

    function setAmount(uint256 _amount) public {
        require(msg.sender == s_owner, "Only onwer can update like amount!");
        require(_amount > 0, "Only greater than 0 values are allowed");

        s_amount = _amount;
    }
}
