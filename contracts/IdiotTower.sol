// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

  Counters.Counter private _tokenId;
  Counters.Counter private _ownerTokenCount;

  // array of colorURI that is matched according to the random index
  string[6] public colorURIArray = [
    "QmTG3A8rq5BQZwqLiJABEVsge2jjGre5XF9v5dDLyxhYmx", //red
    "Qmf7g9bVgHZDq4SydhPnPFfpkt3zndftAo8gPMF671Gi21", //green
    "QmSCEpSDxzQ6fB9jdbbAVEzHHwrgSpRh86tfG4SmpXVRtL", //blue
    "QmYD6rjhhqrutAFNFP4KjfQnvgWwrjJNccEsW9hG4bt555", //black
    "QmY7K9ChdowJEPTT8fUAJvEy9UJTcGY6nXXoiTLXmpPtiR", //gray
    "QmXfcgkDCQ3a1mJDsHRhNqY7yNtGo6hRoDAJGs3xS6dKYa" //white
  ];

  //0 : red, 1: green, 2: blue, 3: black, 4:gray, 5: white
  TokenColor rgbCounter;
  TokenColor bgwCounter;
  mapping(uint256 => string) public setTokenURI;

  struct TokenData {
    uint256 tokenId;
    string tokenURI; //46byte
  }

  /**
   * [ Using uint80 to track count ]
   *  1) It's almost impossible to mint more than total 2**80 NFTs
   *  2) By the raw of big number, sum of each number cannot exceed 2**80 or similar number
   *  3) Therefore, using uint80 to keep track of sum would not be bug.
   */
  struct TokenColor {
    uint80 alpha;
    uint80 beta;
    uint80 gamma;
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

        setTokenURI[tokenId] = colorURIArray[colorIndex];
        // tokenColorCount[colorIndex]++;
        rgbbgw[colorIndex]++;

        // tokenId |= color << 240;

        _safeMint(msg.sender, tokenId);
        _ownerTokenCount.increment();
        ++i;
      }
    } while (i < count);
    rgbCounter = TokenColor(rgbbgw[0], rgbbgw[1], rgbbgw[2]);
    bgwCounter = TokenColor(rgbbgw[3], rgbbgw[4], rgbbgw[5]);
  }

  /// @notice can mint under 200 at a time
  /// @notice the price per token is 0.001 ether
  /// @param count number that you want to mint
  function mint(uint256 count) public payable {
    require(msg.sender != owner(), "Owner can't mint this token");
    require(count < MAX_MINT_NUMBER, "can mint under 200 at a time");
    require(0.001 ether * count < msg.value, "Caller sent lower than price");

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

        // tokenColorCount[colorIndex]++;
        setTokenURI[tokenId] = colorURIArray[colorIndex];
        rgbbgw[colorIndex]++;
        _safeMint(msg.sender, tokenId);
        ++i;
      }
    } while (i < count);
    rgbCounter = TokenColor(rgbbgw[0], rgbbgw[1], rgbbgw[2]);
    bgwCounter = TokenColor(rgbbgw[3], rgbbgw[4], rgbbgw[5]);
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

    if ((from != address(0)) && ((userStatus[from] & 2) == 0)) {
      userStatus[from] |= 2;
      cowardList.push(from);
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
      tokenData[i] = TokenData(tokenId, setTokenURI[tokenId]);
    }
    return tokenData;
  }

  /// @notice you should input the index.
  /// @param colorIndex => 0 : red, 1: green, 2: blue, 3: black, 4:gray, 5: white
  /// @return uint80 count of color
  function countTokenColor(uint256 colorIndex) external view returns (uint80) {
    if (colorIndex == 0) {
      return rgbCounter.alpha;
    } else if (colorIndex == 1) {
      return rgbCounter.beta;
    } else if (colorIndex == 2) {
      return rgbCounter.gamma;
    } else if (colorIndex == 3) {
      return bgwCounter.alpha;
    } else if (colorIndex == 4) {
      return bgwCounter.beta;
    } else {
      return bgwCounter.gamma;
    }
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
