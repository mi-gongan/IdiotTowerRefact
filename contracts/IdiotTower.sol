// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/// @author mi_gongan
/// @title Idiot Tower
contract IdiotTower is ERC721Enumerable, Ownable {
  constructor() ERC721("IdiotTower", "IDIOT") {}

  using Counters for Counters.Counter;

  /**
   * ======================
   * Storages
   * ========================
   */
  uint256 public constant MAX_MINT_NUMBER = 200;
  uint256 public constant STANDARD_PRICE = 0.001 ether;

  bool public justChange = false;

  Counters.Counter private _tokenId;
  Counters.Counter private _ownerTokenCount;

  //0 : red, 1: green, 2: blue, 3: black, 4:gray, 5: white
  mapping(uint256 => uint256) public setColorIndex;
  uint256[6] public tokenColorCount = [0, 0, 0, 0, 0, 0];

  // string[6] public colorURIArray = [
  //   "QmTG3A8rq5BQZwqLiJABEVsge2jjGre5XF9v5dDLyxhYmx", //red
  //   "Qmf7g9bVgHZDq4SydhPnPFfpkt3zndftAo8gPMF671Gi21", //green
  //   "QmSCEpSDxzQ6fB9jdbbAVEzHHwrgSpRh86tfG4SmpXVRtL", //blue
  //   "QmYD6rjhhqrutAFNFP4KjfQnvgWwrjJNccEsW9hG4bt555", //black
  //   "QmY7K9ChdowJEPTT8fUAJvEy9UJTcGY6nXXoiTLXmpPtiR", //gray
  //   "QmXfcgkDCQ3a1mJDsHRhNqY7yNtGo6hRoDAJGs3xS6dKYa" //white
  // ];

  struct TokenData {
    uint256 tokenId;
    uint256 colorIndex;
  }

  address[] public userList;
  address[] public cowardList;

  // 0: not minted, not coward
  // 1: minted, not coward
  // 2: not minted, coward
  // 3: minted, coward
  mapping(address => uint256) public userStatus;

  /**
   * ======================
   * functions
   * ========================
   */

  /// @notice can mint under 200 at a time
  /// @notice Owner can mint token below 200
  /// @param count number that you want to mint
  function ownerMint(uint256 count) public onlyOwner {
    require(
      _ownerTokenCount.current() + count < 201,
      "Owner can mint token below 200"
    );
    require(count < MAX_MINT_NUMBER, "can mint under 200 at a time");

    if ((userStatus[msg.sender] & 1) == 0) {
      userStatus[msg.sender] |= 1;
      userList.push(msg.sender);
    }
    uint8[6] memory rgbbgw = [0, 0, 0, 0, 0, 0];
    uint256 i = 0;
    do {
      unchecked {
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        uint256 colorIndex = uint256(
          keccak256(abi.encodePacked(block.timestamp, tokenId))
        ) % 6;

        setColorIndex[tokenId] = colorIndex;
        rgbbgw[colorIndex]++;

        _safeMint(msg.sender, tokenId);
        _ownerTokenCount.increment();
        ++i;
      }
    } while (i < count);
    unchecked {
      for (uint256 j = 0; i < 6; i++) {
        tokenColorCount[j] += rgbbgw[j];
      }
    }
  }

  /// @notice can mint under 200 at a time
  /// @notice the price per token is STANDARD_PRICE
  /// @param count number that you want to mint
  function mint(uint256 count) public payable {
    require(msg.sender != owner(), "Owner can't mint this token");
    require(count < MAX_MINT_NUMBER, "can mint under 200 at a time");
    require(STANDARD_PRICE * count < msg.value, "Caller sent lower than price");

    if ((userStatus[msg.sender] & 1) == 0) {
      userStatus[msg.sender] |= 1;
      userList.push(msg.sender);
    }
    uint256 i = 0;
    uint8[6] memory rgbbgw = [0, 0, 0, 0, 0, 0];
    do {
      unchecked {
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        uint256 colorIndex = uint256(
          keccak256(abi.encodePacked(block.timestamp, tokenId))
        ) % 6;

        setColorIndex[tokenId] = colorIndex;
        rgbbgw[colorIndex]++;
        _safeMint(msg.sender, tokenId);
        ++i;
      }
    } while (i < count);
    unchecked {
      for (uint256 j = 0; i < 6; i++) {
        tokenColorCount[j] += rgbbgw[j];
      }
    }
  }

  /// @dev this function mint the token of color that you want
  function wantColorOwnerMint(uint256 colorIndex, uint256 count) public {
    require(
      _ownerTokenCount.current() + count < 201,
      "Owner can mint token below 200"
    );
    require(count < MAX_MINT_NUMBER, "can mint under 200 at a time");

    if ((userStatus[msg.sender] & 1) == 0) {
      userStatus[msg.sender] |= 1;
      userList.push(msg.sender);
    }
    uint256 i = 0;
    do {
      unchecked {
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();

        setColorIndex[tokenId] = colorIndex;
        _safeMint(msg.sender, tokenId);
        _ownerTokenCount.increment();
        ++i;
      }
    } while (i < count);
    tokenColorCount[colorIndex] += count;
  }

  function roughColorRatio(uint256 colorIndex) public view returns (uint256) {
    return (1 - countTokenColor(colorIndex)) / (1 + totalSupply());
  }

  /// @dev this function mint the token of color that you want
  /// @notice price is (wantColorMintPrice) * count +0.01
  function wantColorMint(uint256 colorIndex, uint256 count) public payable {
    require(msg.sender != owner(), "Owner can't mint this token");
    require(count < MAX_MINT_NUMBER, "can mint under 200 at a time");
    require(
      STANDARD_PRICE * 4 * roughColorRatio(colorIndex) * count < msg.value,
      "Caller sent lower than price"
    );
    if ((userStatus[msg.sender] & 1) == 0) {
      userStatus[msg.sender] |= 1;
      userList.push(msg.sender);
    }
    uint256 i = 0;
    do {
      unchecked {
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();

        setColorIndex[tokenId] = colorIndex;
        _safeMint(msg.sender, tokenId);
        ++i;
      }
    } while (i < count);
    tokenColorCount[colorIndex] += count;
  }

  /// @dev Through this function, you can change one token of color to want after three by burning three token of same color
  function mintThreeColorToOneColor(
    uint256 tokenId_1,
    uint256 tokenId_2,
    uint256 tokenId_3,
    uint256 wantColorIndex
  ) public {
    require(
      (ownerOf(tokenId_1) == msg.sender) &&
        (ownerOf(tokenId_2) == msg.sender) &&
        (ownerOf(tokenId_3) == msg.sender),
      "you are not token owner"
    );
    require(
      setColorIndex[tokenId_1] == setColorIndex[tokenId_2] &&
        setColorIndex[tokenId_1] == setColorIndex[tokenId_3],
      "The color of tokens is different"
    );
    _burn(tokenId_1);
    _burn(tokenId_2);
    _burn(tokenId_3);
    if (msg.sender != owner()) {
      wantColorMint(wantColorIndex, 1);
    } else {
      wantColorOwnerMint(wantColorIndex, 1);
    }
  }

  function colorChangeBetweenUser(
    address user1,
    address user2,
    uint256 token1,
    uint256 token2
  ) public {
    justChange = true;
    _transfer(user1, user2, token1);
    _transfer(user2, user1, token2);
    justChange = false;
  }

  function getUserList() external view returns (address[] memory) {
    return userList;
  }

  function getCowardList() external view returns (address[] memory) {
    return cowardList;
  }

  function checkUserHaveMinted(address _userAddress)
    external
    view
    returns (bool)
  {
    return (userStatus[_userAddress] & 1) != 0;
  }

  function checkUserIsCoward(address _userAddress)
    external
    view
    returns (bool)
  {
    return (userStatus[_userAddress] & 2) != 0;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);

    if (
      (from != address(0)) &&
      ((userStatus[from] & 2) == 0) &&
      (justChange == false)
    ) {
      userStatus[from] |= 2;
      cowardList.push(from);
    }
  }

  /// @dev if you burn, count of color decrease
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._afterTokenTransfer(from, to, tokenId);
    if (to == address(0)) {
      uint256 burnColorIndex = setColorIndex[tokenId];
      tokenColorCount[burnColorIndex] -= countTokenColor(burnColorIndex);
      if (from == owner() && _ownerTokenCount.current() > 0) {
        _ownerTokenCount.decrement();
      }
    }
  }

  //require for frontend

  /// @param _userAddress address of user that want to show tokens
  /// @return memory return tokens that the user have
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
      tokenData[i] = TokenData(tokenId, setColorIndex[tokenId]);
    }
    return tokenData;
  }

  /// @notice you should input the index.
  /// @param colorIndex => 0 : red, 1: green, 2: blue, 3: black, 4:gray, 5: white
  /// @return uint256 count of color
  function countTokenColor(uint256 colorIndex) public view returns (uint256) {
    return tokenColorCount[colorIndex];
  }

  function getColor(uint256 tokenId) public view returns (uint256) {
    return setColorIndex[tokenId];
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
