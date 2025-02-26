// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {SimpleMultiSig} from "./SimpleMultiSig.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PriceConvertor} from "./PriceConvertor.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";

contract MatchMaking is PriceConvertor {
    address public s_owner;
    uint256 public s_likeAmountInCents = 300; // in cents
    uint256 public s_likeExpirationDays = 7;

    string private errorMsg;

    struct ILike {
        bool like;
        uint256 timestamp;
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
        uint256 _amountInCents, // in cents
        uint256 _likeExpirationDays,
        address priceFeedAddress
    ) PriceConvertor(priceFeedAddress) {
        s_likeAmountInCents = _amountInCents;
        s_likeExpirationDays = _likeExpirationDays;
        s_owner = msg.sender;
        updateErrorMsg();
    }

    function like(address target) external payable {
        uint amountSent = getPriceInCents(msg.value);
        require(msg.sender != target, "Cannot like yourself");
        require(!s_likes[msg.sender][target].like, "Already liked this user");
        require(amountSent == s_likeAmountInCents, errorMsg);

        ILike memory tmp = ILike({like: true, timestamp: block.timestamp});

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

        uint amountToTransfer = getWeiFromCents(2 * s_likeAmountInCents);
        amountToTransfer = (amountToTransfer * 8) / 10;

        // transfer fund: 90% of total
        (bool success, ) = payable(simpleMultiSig).call{
            value: amountToTransfer
        }("");

        if (success) {
            emit MultiSigCreated(address(simpleMultiSig), user1, user2);
        }

        require(success, "Transfer to multisig walled failed!");
    }

    function transferToOwner(uint256 amount) public {
        require(msg.sender == s_owner, "Only onwer can withdraw");
        require(amount > 0, "Amount cannot be 0.");
        require(
            amount <= address(this).balance,
            "Amount cannot be greater than contract's balance."
        );
        (bool success, ) = payable(s_owner).call{value: amount}("");
        require(success, "Payment Failed.");
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

        tmp.like = false;
        tmp.timestamp = 0;
        s_likes[user1][user2] = tmp;
        refundExpiredLike(user1);
    }

    function refundExpiredLike(address liker) internal {
        uint refundAmount = getWeiFromCents(s_likeAmountInCents);
        (bool success, ) = payable(liker).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
    }

    // in cents
    function setLikeAmount(uint256 _amount) external {
        require(msg.sender == s_owner, "Only onwer can update like amount!");
        require(_amount > 0, "Only greater than 0 values are allowed");

        s_likeAmountInCents = _amount;
        updateErrorMsg();
    }

    function setLikeExpirationDays(uint256 _days) external {
        require(
            msg.sender == s_owner,
            "Only onwer can update like expiration days!"
        );
        require(_days > 0, "Only greater than 0 values are allowed");

        s_likeExpirationDays = _days;
    }

    function updateErrorMsg() internal {
        uint256 dollars = s_likeAmountInCents / 100;
        uint256 cents = s_likeAmountInCents % 100;

        errorMsg = string.concat(
            "Amount should be $",
            Strings.toString(dollars),
            ".",
            cents < 10 ? "0" : "",
            Strings.toString(cents)
        );
    }

    receive() external payable {}
}
