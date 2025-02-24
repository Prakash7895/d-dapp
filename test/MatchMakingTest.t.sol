// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {MatchMaking} from "../src/MatchMaking.sol";

contract MatchMakingTest is Test {
    MatchMaking matchMaking;

    address USER1 = address(0xaF3A89D6B8ECBD83510aF833d82D8A7e706379Bb);
    address USER2 = address(0x4e281a642ba67Cf4851366EA463dcd76b1bFa491);

    function setUp() public {
        matchMaking = MatchMaking(0x8C85db386CA5F169dFE5E2431429AD4596b2d2D5);
    }

    function testUserCanLike() public {
        vm.prank(USER1);
        matchMaking.like(USER2);

        bool liked = matchMaking.likes(USER1, USER2);

        assertEq(liked, true);
    }
}
