// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IdiotTower is ERC721Enumerable, Ownable {
  constructor() ERC721("IdiotTower", "IDIOT") {}

  uint256 public constant maxMintNumber = 200;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenId;
  Counters.Counter private _ownerTokenCount;

  string[6] public tokenURIArray = [
    "QmTG3A8rq5BQZwqLiJABEVsge2jjGre5XF9v5dDLyxhYmx", //red
    "Qmf7g9bVgHZDq4SydhPnPFfpkt3zndftAo8gPMF671Gi21", //green
    "QmSCEpSDxzQ6fB9jdbbAVEzHHwrgSpRh86tfG4SmpXVRtL", //blue
    "QmYD6rjhhqrutAFNFP4KjfQnvgWwrjJNccEsW9hG4bt555", //black
    "QmY7K9ChdowJEPTT8fUAJvEy9UJTcGY6nXXoiTLXmpPtiR", //gray
    "QmXfcgkDCQ3a1mJDsHRhNqY7yNtGo6hRoDAJGs3xS6dKYa" //white
  ];

  //0 : red, 1: green, 2: blue, 3: black, 4:gray, 5: white
  mapping(uint256 => uint256) public tokenColorCount;
  mapping(uint256 => string) public setTokenURI;

  struct TokenData {
    uint256 tokenId;
    string tokenURI;
  }

  address[] public userList;
  address[] public cowardList;

  // 0: not minted, not coward
  // 1: minted, not coward
  // 2: not minted, coward
  // 3: minted, coward
  mapping(address => uint256) public userStatus;

  function ownerMint(uint256 count) public onlyOwner {
    require(
      _ownerTokenCount.current() + count < 201,
      "Owner can mint token below 200"
    );
    require(count < maxMintNumber);

    if ((userStatus[msg.sender]) == 0) {
      userStatus[msg.sender] = 1;
      userList.push(msg.sender);
    } else if ((userStatus[msg.sender]) == 2) {
      userStatus[msg.sender] = 3;
      userList.push(msg.sender);
    }

    for (uint256 i = 0; i < count; i++) {
      _tokenId.increment();
      uint256 tokenId = _tokenId.current();
      uint256 colorIndex = uint256(
        keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))
      ) % 6;

      setTokenURI[tokenId] = tokenURIArray[colorIndex];
      tokenColorCount[colorIndex]++;

      _safeMint(msg.sender, tokenId);
      _ownerTokenCount.increment();
    }
  }

  function mint(uint256 count) public payable {
    require(msg.sender != owner(), "Owner can't mint this token");
    require(count < maxMintNumber);
    require(0.001 ether * count < msg.value, "Caller sent lower than price");

    if ((userStatus[msg.sender] & 1) == 0) {
      userStatus[msg.sender] |= 1;
      userList.push(msg.sender);
    }

    for (uint256 i = 0; i < count; i++) {
      _tokenId.increment();
      uint256 tokenId = _tokenId.current();
      uint256 colorIndex = uint256(
        keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))
      ) % 6;

      tokenColorCount[colorIndex]++;
      setTokenURI[tokenId] = tokenURIArray[colorIndex];

      _safeMint(msg.sender, tokenId);
    }
  }

  function countTokenColor(uint256 colorIndex) external view returns (uint256) {
    return tokenColorCount[colorIndex];
  }

  function getUserList() external view returns (address[] memory) {
    return userList;
  }

  function getCowardList() external view returns (address[] memory) {
    return cowardList;
  }

  function checkUserHaveMinted(address _userAddress)
    public
    view
    returns (bool)
  {
    return (userStatus[_userAddress] == 1) || (userStatus[_userAddress] == 3);
  }

  function checkUserIsCoward(address _userAddress) public view returns (bool) {
    return (userStatus[_userAddress] & 2) != 0;
  }

  function justTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(ownerOf(tokenId) == from, "You are not owner of token");
    transferFrom(from, to, tokenId);

    if ((userStatus[from] & 2) == 0) {
      userStatus[from] |= 2;
      cowardList.push(from);
    }
  }

  //require for frontend

  function getTokens(address _userAddress)
    external
    view
    returns (TokenData[] memory)
  {
    uint256 balanceLength = balanceOf(_userAddress);
    require(balanceLength != 0, "Owner did not have token.");

    TokenData[] memory tokenData = new TokenData[](balanceLength);
    for (uint256 i = 0; i < balanceLength; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(_userAddress, i);
      tokenData[i] = TokenData(tokenId, tokenURIArray[tokenId]);
    }
    return tokenData;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
