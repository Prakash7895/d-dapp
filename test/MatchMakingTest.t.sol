// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MatchMaking} from "../src/MatchMaking.sol";
import {DeployMatchMaking} from "../script/DeployMatchMaking.s.sol";

contract MatchMakingTest is Test {
    MatchMaking matchMaking;
    DeployMatchMaking deployer;

    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");
    address OWNER;

    uint constant likeAmount = 500;

    function setUp() public {
        deployer = new DeployMatchMaking();
        matchMaking = deployer.run();
        OWNER = matchMaking.s_owner();
        // vm.deal(OWNER, 10 ether);
        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);
    }

    function testUserCanLike() public {
        uint tmp = matchMaking.getPriceInCents(1e18);
        console.log("AMOUNT::", tmp);

        uint requiredWei = ((likeAmount + 1) * 1e18) / tmp;
        console.log("requiredWei::", requiredWei);

        vm.prank(USER1);
        matchMaking.like{value: requiredWei}(USER2);

        (bool liked, uint256 timestamp, uint256 amount) = matchMaking.s_likes(
            USER1,
            USER2
        );

        assertEq(liked, true);
    }

    function testNewAmount() public {
        console.log("Onwer", OWNER);
        console.logAddress(matchMaking.s_owner());

        uint newLikeAmount = 300;
        vm.prank(OWNER);
        matchMaking.setLikeAmount(newLikeAmount);

        uint tmp = matchMaking.getPriceInCents(1e18);
        console.log("AMOUNT::", tmp);

        uint requiredWei = ((newLikeAmount + 1) * 1e18) / tmp;
        console.log("requiredWei::", requiredWei);

        vm.prank(USER1);
        matchMaking.like{value: requiredWei}(USER2);
        (bool liked, uint256 timestamp, uint256 amount) = matchMaking.s_likes(
            USER1,
            USER2
        );
        console.log("balance", address(matchMaking).balance);

        assertEq(liked, true);
    }

    function testCanSet0Amount() public {
        vm.expectRevert();
        vm.prank(OWNER);
        matchMaking.setLikeAmount(0);
    }

    function testLikeExpirationDays() public {
        vm.prank(OWNER);
        matchMaking.setLikeExpirationDays(3);

        uint256 _days = matchMaking.s_likeExpirationDays();

        assertEq(_days, 3);
    }

    function testTransferToOwner() public {
        vm.expectRevert();
        console.log("balance", address(matchMaking).balance);
        matchMaking.transferToOwner(3);
    }

    function testTransferToOwnerZeroBalance() public {
        console.log("balance", address(matchMaking).balance);
        vm.expectRevert();
        vm.prank(OWNER);
        matchMaking.transferToOwner(3);
    }

    function testTransferSuccess() public {
        testUserCanLike();
        uint balance = address(matchMaking).balance;
        console.log("balance11", balance);

        console.log("s_owner", matchMaking.s_owner());

        uint ownerBalance = address(OWNER).balance;
        console.log("ownerBalance1", ownerBalance);

        uint amountTransferred = balance;
        console.log("amountTransferred", amountTransferred);

        vm.prank(OWNER);
        matchMaking.transferToOwner(amountTransferred);

        uint ownerNewBalance = address(OWNER).balance;
        console.log("ownerNewBalance2", ownerNewBalance);

        uint newBalance = address(matchMaking).balance;
        console.log("matchMaking newBalance", newBalance);

        assertEq(ownerBalance + amountTransferred, ownerNewBalance);
    }

    function testUnsetLikeOnExpiration() public {
        testUserCanLike();

        uint expirationDays = matchMaking.s_likeExpirationDays();
        console.log("expirationDays", expirationDays);

        (bool like12, uint timestamp12, uint amount12) = matchMaking.s_likes(
            USER1,
            USER2
        );
        (bool like21, uint timestamp21, uint amount21) = matchMaking.s_likes(
            USER2,
            USER1
        );
        console.log("like12", like12);
        console.log("timestamp12", timestamp12);
        console.log("like21", like21);
        console.log("timestamp21", timestamp21);

        console.log("block.timestamp", block.timestamp);

        uint user1Balance = address(USER1).balance;
        console.log("user1Balance", user1Balance);

        vm.warp(block.timestamp + expirationDays * 1 days + 1);
        console.log("block.timestampNEW", block.timestamp);
        vm.prank(USER1);
        matchMaking.unSetLikeOnExpiration(USER1, USER2);

        uint user1BalanceNow = address(USER1).balance;
        console.log("user1BalanceNow", user1BalanceNow);

        (bool like, uint timestamp, uint _amount) = matchMaking.s_likes(
            USER1,
            USER2
        );

        console.log("Like", like);
        console.log("timestamp1111", timestamp);

        assertEq(timestamp, 0);

        assert(user1BalanceNow > user1Balance);
    }

    function testUnsetBeforeExpirationLimit() public {
        testUserCanLike();
        vm.prank(OWNER);
        vm.expectRevert();
        matchMaking.unSetLikeOnExpiration(USER1, USER2);

        (bool like, uint timestamp, uint _amount) = matchMaking.s_likes(
            USER1,
            USER2
        );

        console.log("Like", like);
        console.log("timestamp1111", timestamp);
    }

    function testTransferToMultiSigWallet() public {
        uint tmp = matchMaking.getPriceInCents(1e18);
        console.log("AMOUNT::", tmp);

        uint requiredWei = ((likeAmount + 1) * 1e18) / tmp;
        console.log("requiredWei::", requiredWei);

        uint tmpWei = matchMaking.getWeiFromCents(2 * (likeAmount + 1));
        console.log("tmpWei::", tmpWei, (tmpWei * 8) / 10);

        vm.prank(USER1);
        matchMaking.like{value: requiredWei}(USER2);

        vm.prank(USER2);
        vm.recordLogs();
        matchMaking.like{value: requiredWei}(USER1);

        (bool liked12, uint256 _timestamp12, uint256 _amount12) = matchMaking
            .s_likes(USER1, USER2);
        (bool liked21, uint256 _timestamp21, uint256 _amount21) = matchMaking
            .s_likes(USER2, USER1);
        console.log("liked12", liked12);
        console.log("liked21", liked21);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool found = false;
        console.log("LEN", entries.length);
        address walletAddress;

        for (uint i = 0; i < entries.length; i++) {
            // If the log topic[0] equals the keccak256 hash of the event signature,
            // then we have our MultiSigCreated event.
            console.log("Log entry", i);
            console.logBytes32(entries[i].topics[0]); // Log the event signature
            if (
                entries[i].topics.length > 0 &&
                entries[i].topics[0] ==
                keccak256("MultiSigCreated(address,address,address)")
            ) {
                // Decode the event data. Note that indexed parameters are in topics.
                // For a typical event like:
                // event MultiSigCreated(address indexed walletAddress, address indexed userA, address indexed userB);
                // The topics are:
                // topics[0]: event signature
                // topics[1]: walletAddress (padded)
                // topics[2]: userA
                // topics[3]: userB
                walletAddress = address(uint160(uint256(entries[i].topics[1])));
                address userA = address(uint160(uint256(entries[i].topics[2])));
                address userB = address(uint160(uint256(entries[i].topics[3])));
                console.log("MultiSig wallet address:", walletAddress);
                console.logAddress(userA);
                console.logAddress(userB);
                found = true;
            }
        }

        console.log("ADDRESS", walletAddress);
        console.log("ADDRESS BALANCE", address(walletAddress).balance);
        assertTrue(found, "MultiSigCreated event not found");
    }

    function testUnsetAfterMatch() public {
        uint tmp = matchMaking.getPriceInCents(1e18);
        console.log("AMOUNT::", tmp);

        uint requiredWei = ((likeAmount + 1) * 1e18) / tmp;
        console.log("requiredWei::", requiredWei);

        vm.prank(USER1);
        matchMaking.like{value: requiredWei}(USER2);

        vm.prank(USER2);
        matchMaking.like{value: requiredWei}(USER1);

        (bool liked12, uint256 _timestamp12, uint256 _amount12) = matchMaking
            .s_likes(USER1, USER2);
        (bool liked21, uint256 _timestamp21, uint256 _amount21) = matchMaking
            .s_likes(USER2, USER1);

        assertEq(liked12, liked21);

        uint expirationDays = matchMaking.s_likeExpirationDays();

        vm.warp(block.timestamp + expirationDays * 1 days + 1);
        vm.expectRevert();
        vm.prank(OWNER);
        matchMaking.unSetLikeOnExpiration(USER1, USER2);
    }
}
