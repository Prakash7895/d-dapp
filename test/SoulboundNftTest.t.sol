// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeploySoulboundNft} from "../script/DeploySoulboundNft.s.sol";
import {SoulboundNft} from "../src/SoulboundNft.sol";

contract SoulboundNftTest is Test {
    DeploySoulboundNft deployer;
    SoulboundNft soulboundNft;

    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");

    string public constant PUG_URI =
        "https://bafybeifkbpoxnjce54toeiofyk2uwzpraemepkfdnptdqrshjcguywm3y4.ipfs.dweb.link?filename=pug.json";

    string constant SHIBA_INU_URI =
        "https://bafybeibw53tgismor4x6qndd66hhb7z33sodya2w3hwoga4vdggobla5fy.ipfs.dweb.link?filename=shiba-inu.json";

    string public constant HAPPY_FACE_URI =
        "https://bafybeibuaozgg5ronl2mn4ttqn4d3272u6j5y2bfi56f2vwioafjdturvi.ipfs.dweb.link?filename=happy.json";

    string public constant SAD_URI =
        "https://bafybeiba6dwtrxs7hyeyewb6yziocxq2zbrqt3lr4qpegusstwtsipr47e.ipfs.dweb.link?filename=sad.json";

    function setUp() public {
        deployer = new DeploySoulboundNft();

        soulboundNft = deployer.run();

        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);
        vm.deal(USER3, 10 ether);

        vm.prank(USER1);
        soulboundNft.createUserProfile{value: 1e15}(PUG_URI);

        vm.prank(USER2);
        soulboundNft.createUserProfile{value: 1e15}(HAPPY_FACE_URI);

        vm.prank(USER2);
        soulboundNft.createUserProfile{value: 1e15}(SAD_URI);

        vm.prank(USER1);
        soulboundNft.createUserProfile{value: 1e15}(SHIBA_INU_URI);
    }

    function testCanCreateUserProfile() public {
        vm.prank(USER1);
        soulboundNft.mintNewNft(PUG_URI);

        string memory token0 = soulboundNft.tokenURI(1);

        assertEq(token0, PUG_URI);
    }

    function testCanUserMintMultipleProfileNft() public view {
        string memory uri1 = soulboundNft.tokenURI(1);
        string memory uri2 = soulboundNft.tokenURI(4);

        string[] memory uris = soulboundNft.getUserTokenUris(USER1);
        for (uint256 i = 0; i < uris.length; i++) {
            console.log("URI=>", i);
            console.logString(uris[i]);
        }

        string memory activeNft = soulboundNft.getActiveProfileNft(USER1);
        console.log("activeNft=>", activeNft);

        assertEq(uri1, PUG_URI);
        assertEq(uri2, SHIBA_INU_URI);
    }

    function testGetActiveProfileNft() public {
        soulboundNft.getUserNfts(USER1);

        string memory activeNft = soulboundNft.getActiveProfileNft(USER1);

        assertEq(activeNft, SHIBA_INU_URI);

        vm.prank(USER1);
        soulboundNft.changeProfileNft(1);

        string memory newActiveNft = soulboundNft.getActiveProfileNft(USER1);

        assertEq(newActiveNft, PUG_URI);
    }

    function testRevertOnChangingOtherUserProfileNft() public {
        vm.expectRevert();
        vm.prank(USER1);
        soulboundNft.changeProfileNft(2);
    }

    function testTransferFrom() public {
        vm.expectRevert();
        vm.prank(USER1);
        soulboundNft.transferFrom(USER1, USER2, 1);
    }

    function testSafeTransferFrom() public {
        vm.expectRevert();
        vm.prank(USER1);
        soulboundNft.safeTransferFrom(USER1, USER2, 1, "");
    }

    function testCheckTokenUriAreCorrect() public view {
        string[] memory setUris = soulboundNft.getUserTokenUris(USER1);
        string[] memory uris = new string[](2);
        uris[0] = PUG_URI;
        uris[1] = SHIBA_INU_URI;

        for (uint256 i = 0; i < uris.length; i++) {
            assertEq(setUris[i], uris[i]);
        }
    }

    function testEmptyProfileNft() public {
        uint256[] memory allTokenIds = soulboundNft.getUserNfts(USER3);
        assertEq(allTokenIds.length, 0);

        vm.expectRevert();
        soulboundNft.getActiveProfileNft(USER3);
    }
}
