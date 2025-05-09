// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {SimpleMultiSig} from "./SimpleMultiSig.sol";
import {Owner} from "./Owner.sol";

contract MatchMaking is Owner {
    uint256 public s_likeExpMinutes;
    uint256 public s_commission;

    struct ILike {
        uint256 amount;
        uint256 timestamp;
        bool like;
    }
    mapping(address => mapping(address => ILike)) public s_likes;

    event Like(address indexed liker, address indexed target);
    event UnLike(address indexed liker, address indexed target);
    event Match(address indexed userA, address indexed userB);
    event MultiSigCreated(
        address indexed walletAddress,
        address indexed userA,
        address indexed userB
    );

    constructor(
        uint256 _amount,
        uint256 _likeExpMinutes,
        uint256 _commission
    ) Owner(msg.sender, _amount, 0) {
        s_likeExpMinutes = _likeExpMinutes;
        s_commission = _commission;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "NOT_OWNER");
        _;
    }

    function like(address target) external payable {
        ILike storage like12 = s_likes[msg.sender][target];
        require(msg.sender != target, "CAN_NOT_LIKE_SELF");
        require(!like12.like, "ALREADY_LIKED");
        require(msg.value == s_amount, "INSUFFICIENT_FUNDS");

        like12.amount = msg.value;
        like12.timestamp = block.timestamp;
        like12.like = true;

        emit Like(msg.sender, target);

        ILike storage like21 = s_likes[target][msg.sender];
        if (like21.like) {
            emit Match(msg.sender, target);

            SimpleMultiSig simpleMultiSig = new SimpleMultiSig(
                msg.sender,
                target
            );

            uint total = (like12.amount + like21.amount);
            uint commissionAmount = (total * s_commission) / 100;
            uint amountToTransfer = total - commissionAmount;

            require(
                address(this).balance >= amountToTransfer,
                "INSUFFICIENT_BALANCE"
            );

            (bool success, ) = payable(simpleMultiSig).call{
                value: amountToTransfer
            }("");
            require(success, "TRANSFER_FAILED");

            s_maxAmountCanWithdraw += commissionAmount;

            emit MultiSigCreated(address(simpleMultiSig), msg.sender, target);
        }
    }

    function unSetLikeOnExpiration(address target) external {
        ILike storage tmp = s_likes[msg.sender][target];
        require(tmp.like, "NOT_LIKED_OR_NOT_OWNER");
        ILike storage tmp1 = s_likes[target][msg.sender];
        if (tmp.like && tmp1.like) {
            revert("ALREADY_MATCHED");
        }

        require(
            (block.timestamp - tmp.timestamp) > (s_likeExpMinutes * 1 minutes),
            "LIKE_NOT_EXPIRED"
        );

        uint256 amountToRefund = tmp.amount;

        tmp.amount = 0;
        tmp.timestamp = 0;
        tmp.like = false;

        emit UnLike(msg.sender, target);
        (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        require(success, "REFUND_FAILED");
    }

    function setLikeExpirationDays(uint256 _minutes) external onlyOwner {
        require(_minutes > 0, "POSITIVE_MINUTES");

        s_likeExpMinutes = _minutes;
    }

    function setCommission(uint256 _commission) external onlyOwner {
        bool inRange = _commission > 0 && _commission < 100;
        require(inRange, "BETWEEN_0_AND_100");

        s_commission = _commission;
    }

    receive() external payable {}
}
