// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

contract MatchMaking {
    mapping(address => mapping(address => bool)) public likes;

    event Liked(address indexed liker, address indexed target);

    event Match(address indexed userA, address indexed userB);

    function like(address target) external {
        require(msg.sender != target, "Cannot like yourself");
        require(!likes[msg.sender][target], "Already liked this user");

        likes[msg.sender][target] = true;
        emit Liked(msg.sender, target);

        if (likes[target][msg.sender]) {
            emit Match(msg.sender, target);
        }
    }
}
