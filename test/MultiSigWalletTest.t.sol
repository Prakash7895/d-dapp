// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console, Vm} from "forge-std/Test.sol";
import {DeployMultiSigWallet} from "./../script/DeployMultiSigWallet.s.sol";
import {MatchMaking} from "./../src/MatchMaking.sol";
import {SimpleMultiSig, ProposalStatus} from "./../src/SimpleMultiSig.sol";

contract MultiSigWalletTest is Test {
    MatchMaking matchMaking;

    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");
    address USER4 = makeAddr("USER4");
    address OWNER;

    uint constant likeAmount = 500;

    address walletAddress;
    SimpleMultiSig simpleMultiSig;

    function setUp() public {
        DeployMultiSigWallet deployMultiSigWallet = new DeployMultiSigWallet();

        matchMaking = deployMultiSigWallet.run();
        OWNER = matchMaking.s_owner();

        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);

        uint tmp = matchMaking.getPriceInCents(1e18);

        uint requiredWei = ((likeAmount + 1) * 1e18) / tmp;

        vm.prank(USER1);
        matchMaking.like{value: requiredWei}(USER2);

        vm.prank(USER2);
        vm.recordLogs();
        matchMaking.like{value: requiredWei}(USER1);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool found = false;

        for (uint i = 0; i < entries.length; i++) {
            if (
                entries[i].topics.length > 0 &&
                entries[i].topics[0] ==
                keccak256("MultiSigCreated(address,address,address)")
            ) {
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
        simpleMultiSig = SimpleMultiSig(payable(walletAddress));
    }

    function testWalletHasSomeBalance() public view {
        assert(address(walletAddress).balance > 0);
    }

    function testValidOnwers() public view {
        address owner1 = simpleMultiSig.s_owners(0);
        address owner2 = simpleMultiSig.s_owners(1);

        assertEq(USER2, owner1);
        assertEq(USER1, owner2);
    }

    function testCanOtherUserSubmitProposal() public {
        uint balance = address(walletAddress).balance;
        vm.prank(USER3);
        vm.expectRevert();
        simpleMultiSig.submitProposal(payable(USER4), balance / 3);
    }

    function testCanOnwersSubmitProposal() public {
        uint balance = address(walletAddress).balance;
        vm.prank(USER2);
        uint amount = balance / 3;
        simpleMultiSig.submitProposal(payable(USER4), amount);

        (
            address payable dest,
            uint _amount,
            uint approvals,
            bool executed,
            ProposalStatus status
        ) = simpleMultiSig.s_proposals(0);

        assert(dest == USER4);
        assert(_amount == amount);
        assert(approvals == 1);
        assert(executed == false);
        assert(status == ProposalStatus.ACTIVE);
    }

    function testCanOwnerApproveNonExistingProposal() public {
        testCanOnwersSubmitProposal();

        vm.prank(USER1);
        vm.expectRevert();
        simpleMultiSig.approveProposal(1);
    }

    function testCanOtherUserApproveProposal() public {
        testCanOnwersSubmitProposal();

        vm.prank(USER4);
        vm.expectRevert();
        simpleMultiSig.approveProposal(0);
    }

    function testCanApprovedUserApproveProposal() public {
        testCanOnwersSubmitProposal();

        vm.prank(USER2);
        vm.expectRevert();
        simpleMultiSig.approveProposal(0);
    }

    function testCanApproveProposal() public {
        testCanOnwersSubmitProposal();

        uint user4Balance = address(USER4).balance;
        console.log("user4Balance1", user4Balance);

        vm.prank(USER1);
        simpleMultiSig.approveProposal(0);

        uint user4BalanceNow = address(USER4).balance;
        console.log("user4BalanceNow", user4BalanceNow);

        (
            address payable dest,
            uint _amount,
            uint approvals,
            bool executed,
            ProposalStatus status
        ) = simpleMultiSig.s_proposals(0);

        assert(dest == USER4);
        assert(approvals == 2);
        assert(executed == true);
        assert(user4BalanceNow == _amount);
        assert(status == ProposalStatus.ACTIVE);

        vm.expectRevert();
        vm.prank(USER1);
        simpleMultiSig.inactivateProposal(0);
    }

    function testCanInactivateProposal() public {
        testCanOnwersSubmitProposal();

        vm.prank(USER1);
        simpleMultiSig.inactivateProposal(0);

        (
            address payable dest,
            uint _amount,
            uint approvals,
            bool executed,
            ProposalStatus status
        ) = simpleMultiSig.s_proposals(0);

        assert(status == ProposalStatus.INACTIVE);

        vm.expectRevert();
        vm.prank(USER1);
        simpleMultiSig.approveProposal(0);
    }
}
