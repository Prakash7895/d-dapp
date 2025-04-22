// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {SimpleMultiSig} from "./SimpleMultiSig.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PriceConvertor} from "./PriceConvertor.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {Owner} from "./Owner.sol";

contract MatchMaking is PriceConvertor, Owner {
    uint256 public s_likeExpirationDays = 7;
    uint256 public s_commission = 80;

    struct ILike {
        bool like;
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address => mapping(address => ILike)) public s_likes;

    event Like(address indexed liker, address indexed target);

    event Match(address indexed userA, address indexed userB);

    event MultiSigCreated(
        address indexed walletAddress,
        address indexed userA,
        address indexed userB
    );

    constructor(
        uint256 _amount,
        uint256 _likeExpirationDays,
        address priceFeedAddress
    ) PriceConvertor(priceFeedAddress) Owner(msg.sender, _amount) {
        s_likeExpirationDays = _likeExpirationDays;
    }

    function like(address target) external payable {
        require(msg.sender != target, "Cannot like yourself");
        require(!s_likes[msg.sender][target].like, "Already liked this user");
        require(msg.value == s_amount, "Insufficient like amount");

        ILike memory tmp = ILike({
            like: true,
            timestamp: block.timestamp,
            amount: msg.value
        });

        s_likes[msg.sender][target] = tmp;

        emit Like(msg.sender, target);

        if (s_likes[target][msg.sender].like) {
            emit Match(msg.sender, target);
            transferFundToMultiSigWallet(msg.sender, target);
        }
    }

    function transferFundToMultiSigWallet(
        address user1,
        address user2
    ) internal {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        // create a multisig wallet
        SimpleMultiSig simpleMultiSig = new SimpleMultiSig(users, 2);

        uint amountToTransfer = (s_likes[user1][user2].amount +
            s_likes[user2][user1].amount);
        amountToTransfer = (amountToTransfer * s_commission) / 100;

        // transfer fund: 90% of total
        (bool success, ) = payable(simpleMultiSig).call{
            value: amountToTransfer
        }("");

        if (success) {
            emit MultiSigCreated(address(simpleMultiSig), user1, user2);
        }

        require(success, "Transfer to multisig walled failed!");
    }

    // call this from cron job, set likes[user1][user2] = {like: false, timestamp: 0}
    // if not matched within like expiration limit
    function unSetLikeOnExpiration(address user1, address user2) external {
        ILike memory tmp = s_likes[user1][user2];
        require(
            tmp.like && msg.sender == user1,
            "Only liker can reset likes and claim refund!"
        );
        ILike memory tmp1 = s_likes[user2][user1];
        if (tmp.like && tmp1.like) {
            revert("Can't unlike after match");
        }

        string memory errorMessage = string.concat(
            "Cannot unset like before (",
            Strings.toString(s_likeExpirationDays),
            ") Days"
        );

        require(
            (block.timestamp - tmp.timestamp) > s_likeExpirationDays * 1 days,
            errorMessage
        );

        uint256 amountToRefund = tmp.amount;

        tmp.like = false;
        tmp.timestamp = 0;
        tmp.amount = 0;
        s_likes[user1][user2] = tmp;
        refundExpiredLike(user1, amountToRefund);
    }

    function refundExpiredLike(address liker, uint256 refundAmount) internal {
        (bool success, ) = payable(liker).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
    }

    function setLikeAmount(uint256 _amount) external {
        setAmount(_amount);
    }

    function setLikeExpirationDays(uint256 _days) external {
        require(
            msg.sender == s_owner,
            "Only onwer can update like expiration days!"
        );
        require(_days > 0, "Only greater than 0 values are allowed");

        s_likeExpirationDays = _days;
    }

    function setCommission(uint256 _commission) external {
        require(msg.sender == s_owner, "Only onwer can update commission!");
        require(_commission > 0, "Only greater than 0 values are allowed");
        require(_commission < 100, "Only less than 100 values are allowed");

        s_commission = _commission;
    }

    receive() external payable {}
}
