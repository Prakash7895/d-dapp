// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {SimpleMultiSig} from "./SimpleMultiSig.sol";
import {PriceConvertor} from "./PriceConvertor.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {Owner} from "./Owner.sol";

contract MatchMaking is PriceConvertor, Owner {
    uint256 public s_likeExpirationDays;
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
        uint256 _likeExpirationDays,
        uint256 _commission,
        address priceFeedAddress
    ) PriceConvertor(priceFeedAddress) Owner(msg.sender, _amount, 0) {
        s_likeExpirationDays = _likeExpirationDays;
        s_commission = _commission;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Only owner can perform this action!");
        _;
    }

    function like(address target) external payable {
        ILike storage likeEntry = s_likes[msg.sender][target];
        require(msg.sender != target, "Cannot like yourself");
        require(!likeEntry.like, "Already liked this user");
        require(msg.value == s_amount, "Insufficient like amount");

        likeEntry.amount = msg.value;
        likeEntry.timestamp = block.timestamp;
        likeEntry.like = true;

        emit Like(msg.sender, target);

        bool isMutualLike = s_likes[target][msg.sender].like;
        if (isMutualLike) {
            emit Match(msg.sender, target);
            transferFundToMultiSigWallet(msg.sender, target);
        }
    }

    function transferFundToMultiSigWallet(
        address user1,
        address user2
    ) internal {
        // create a multisig wallet
        SimpleMultiSig simpleMultiSig = new SimpleMultiSig(user1, user2);

        uint total = (s_likes[user1][user2].amount +
            s_likes[user2][user1].amount);

        uint commissionAmount = (total * s_commission) / 100;

        uint amountToTransfer = total - commissionAmount;

        require(
            address(this).balance >= amountToTransfer,
            "Insufficient contract balance"
        );

        // transfer fund: 90% of total
        (bool success, ) = payable(simpleMultiSig).call{
            value: amountToTransfer
        }("");
        require(success, "Transfer to multisig walled failed!");

        s_maxAmountCanWithdraw += commissionAmount;

        emit MultiSigCreated(address(simpleMultiSig), user1, user2);
    }

    // call this from cron job, set likes[user1][user2] = {like: false, timestamp: 0}
    // if not matched within like expiration limit
    function unSetLikeOnExpiration(address user1, address user2) external {
        ILike storage tmp = s_likes[user1][user2];
        require(
            tmp.like && msg.sender == user1,
            "Only liker can reset likes and claim refund!"
        );
        ILike storage tmp1 = s_likes[user2][user1];
        if (tmp.like && tmp1.like) {
            revert("Can't unlike after match");
        }

        require(
            (block.timestamp - tmp.timestamp) >
                s_likeExpirationDays * 1 minutes,
            "Cannot unset like before expiration"
        );

        uint256 amountToRefund = tmp.amount;

        tmp.amount = 0;
        tmp.timestamp = 0;
        tmp.like = false;

        emit UnLike(user1, user2);
        (bool success, ) = payable(user1).call{value: amountToRefund}("");
        require(success, "Refund transfer failed");
    }

    function setLikeExpirationDays(uint256 _days) external onlyOwner {
        require(_days > 0, "Only greater than 0 values are allowed");

        s_likeExpirationDays = _days;
    }

    function setCommission(uint256 _commission) external onlyOwner {
        bool inRange = _commission > 0 && _commission < 100;
        require(inRange, "commission should be between 0 and 100");

        s_commission = _commission;
    }

    receive() external payable {}
}
