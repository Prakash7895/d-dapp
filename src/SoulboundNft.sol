// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Owner} from "./Owner.sol";

contract SoulboundNft is ERC721URIStorage, Owner {
    uint256 private s_tokenCounter;
    mapping(address => uint256[]) private s_userToTokenIds;
    mapping(address => uint256) private s_activeProfileNft;

    event ProfileMinted(address indexed user, uint256 tokenId, string tokenUri);
    event ActiveNftChanged(address indexed user, uint256 tokenId);

    constructor(
        uint _mintFee
    ) ERC721("ProfileNft", "PN") Owner(msg.sender, _mintFee, 0) {
        s_tokenCounter = 1;
    }

    function s_mintFee() public view returns (uint) {
        return s_amount;
    }

    // when user click on sign up on FE, this fn is called and mints a nft for profile picture
    function verifyUser(string memory tokenUri) public payable {
        require(msg.value >= s_mintFee(), "INSUFFICIENT_FUNDS");

        mintNewNft(tokenUri);
    }

    function mintNewNft(string memory tokenUri) public {
        uint256 tokenId = s_tokenCounter;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenUri);

        s_userToTokenIds[msg.sender].push(tokenId);
        s_activeProfileNft[msg.sender] = tokenId;

        emit ProfileMinted(msg.sender, tokenId, tokenUri);

        unchecked {
            s_tokenCounter++;
        }
    }

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        _;
    }

    function changeProfileNft(uint256 tokenId) public onlyOwner(tokenId) {
        if (s_activeProfileNft[msg.sender] != tokenId) {
            s_activeProfileNft[msg.sender] = tokenId;
            emit ActiveNftChanged(msg.sender, tokenId);
        }
    }

    function getUserNfts(address user) public view returns (uint256[] memory) {
        return s_userToTokenIds[user];
    }

    function getActiveProfileNft(
        address user
    ) public view returns (string memory) {
        uint256 tokenId = s_activeProfileNft[user];
        require(tokenId != 0, "NO_NFT");
        return tokenURI(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override(ERC721, IERC721) {
        revert("NOT_ALLOWED");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public pure override(ERC721, IERC721) {
        revert("NOT_ALLOWED");
    }

    function setMaxWithDrawableAmount() public {
        require(s_owner == msg.sender, "NOT_OWNER");
        s_maxAmountCanWithdraw = address(this).balance;
    }

    receive() external payable {}
}
