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

    constructor(
        uint _mintFee
    ) ERC721("ProfileNft", "PN") Owner(msg.sender, _mintFee) {
        s_tokenCounter = 1;
    }

    function s_mintFee() public view returns (uint) {
        return s_amount;
    }

    // when user click on sign up on FE, this fn is called and mints a nft for profile picture
    function createUserProfile(string memory tokenUri) public payable {
        require(msg.value >= s_mintFee(), "Insufficient mint fee");

        mintNewNft(tokenUri);
    }

    function mintNewNft(string memory tokenUri) public {
        _safeMint(msg.sender, s_tokenCounter);
        _setTokenURI(s_tokenCounter, tokenUri);

        s_userToTokenIds[msg.sender].push(s_tokenCounter);

        s_activeProfileNft[msg.sender] = s_tokenCounter;

        emit ProfileMinted(msg.sender, s_tokenCounter, tokenUri);

        s_tokenCounter++;
    }

    function tokenIdExists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        _;
    }

    function changeProfileNft(uint256 tokenId) public onlyOwner(tokenId) {
        require(tokenIdExists(tokenId), "Token Id does not exist");

        s_activeProfileNft[msg.sender] = tokenId;
    }

    function getUserNfts(address user) public view returns (uint256[] memory) {
        return s_userToTokenIds[user];
    }

    function getActiveProfileNft(
        address user
    ) public view returns (string memory) {
        uint256 tokenId = s_activeProfileNft[user];
        require(tokenId != 0, "Your balance is empty");
        return tokenURI(tokenId);
    }

    function getUserTokenUris(
        address user
    ) public view returns (string[] memory) {
        uint256[] memory tokenIds = s_userToTokenIds[user];
        uint256 totalTokens = tokenIds.length;
        string[] memory uris = new string[](totalTokens);

        for (uint256 i = 0; i < totalTokens; i++) {
            uris[i] = tokenURI(tokenIds[i]);
        }

        return uris;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override(ERC721, IERC721) {
        revert("Not allowed to transfer profile nft..");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public pure override(ERC721, IERC721) {
        revert("Not allowed to transfer profile nft...");
    }

    receive() external payable {}
}
