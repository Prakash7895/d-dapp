// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {SimpleMultiSig} from "./SimpleMultiSig.sol";

contract MatchMaking {
    address private s_owner;

    struct ILike {
        bool like;
        uint256 timestamp;
    }

    mapping(address => mapping(address => ILike)) public likes;

    event Like(address indexed liker, address indexed target);

    event Match(address indexed userA, address indexed userB);

    constructor() {
        s_owner = msg.sender;
    }

    function like(address target) external payable {
        require(msg.sender != target, "Cannot like yourself");
        require(!likes[msg.sender][target].like, "Already liked this user");
        require(msg.value == 0.005 ether, "Insufficient amount!");

        ILike memory tmp = ILike({like: true, timestamp: block.timestamp});

        likes[msg.sender][target] = tmp;

        emit Like(msg.sender, target);

        if (likes[target][msg.sender].like) {
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

        // transfer fund: 90% of total
        (bool success, ) = payable(simpleMultiSig).call{value: 0.009 ether}("");

        require(success, "Transfer to multisig walled failed!");
    }

    function transferToOwner(uint256 amount) public {
        require(msg.sender == s_owner, "Only onwer can withdraw");
        (bool success, ) = payable(s_owner).call{value: amount}("");
        require(success, "Payment Failed.");
    }

    receive() external payable {}
}
