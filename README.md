# IDOIT TOWER 문제

### setting

```
git clone "https://github.com/mi-gongan/IdiotTowerRefact.git"
npm install
```

### compile

```
harhat compile
```

### test

```
harhat test
```

## 개요

가상의 아티스트 그룹 Idiots에서는 자신들만의 NFT를 만들어보고 싶어졌다. 하지만, 이 그룹은 매우 특이한 그룹이라 평범한 NFT로는 만족하지 못하고, 새로운 형태의 NFT를 만들고 싶어졌다.

그들은 다음과 같은 NFT를 만들고 싶어한다.

- 원칙 1) 절대로 쓸모가 있어서는 안된다. => 한번 구매한 NFT를 상대에게 transfer할시 그에 상응하는 가치를 0으로 정한다
- 원칙 2) 보유한 NFT의 수에 따라서 그룹 내 서열을 정한다.
- 원칙 3) 스마트 컨트랙트를 배포한 지갑에 족쇄를 채워, 해당 지갑이 1등이 되는 일을 막는다.
- 원칙 4) 한 번이라도 NFT를 Transfer한 지갑 주소는 “겁쟁이”로 낙인 찍는다.

### +++Idiot Tower 확장

- nft 간에 컬러기반 교환
- 같은 컬러의 NFT 3개를 burn하여 원하는 컬러의 NFT 1개 mint
- 원하는 컬러의 nft를 ETH로 구매 가능 => 구매 가격은 기존 구매 가격 \* 4 \* 해당색상이 전체 갯수 중 차지하는 비율 \* 6
- 마켓 플레이스에서 거래로 인한 transfer가 발생해도, coward가 되지 않도록 설정

## 컨트랙트

### 라이브러리/환경

- 아직 ERC1155 기반 토큰 전송을 지원하지 않는 지갑(metamask)들이 있고 불변성 측면에서 보장된 ERC721 채택 + ERC1155는 소유권 추적도 어렵다.
- 오버플로,언더플로가 발생할 수 있으므로 Counter라는 라이브러리를 사용
- 스마트 컨트랙트를 배포한 지갑 계정을 Owner로 설정 => Ownable 컨트랙트를 상속
- 기본적으로 컴파일과 배포가 자유롭고 테스트를 하기 쉬운 환경인 hardhat 채택

### 함수

- function ownerMint(uint256 count) public onlyOwner {}
  컨트랙트를 배포한 owner가 민팅할 수 있는 함수

- function mint(uint256 count) public payable {}
  일반 사용자들이 민팅할 수 있는 함수 / 0.01ether 지불해야함

- function wantColorOwnerMint(uint256 colorIndex, uint256 count) public {}

- function wantColorMint(uint256 colorIndex, uint256 count) public payable {

- function roughColorRatio(uint256 colorIndex) public view returns (uint256) {

- function mintThreeColorToOneColor( uint256 tokenId_1, uint256 tokenId_2, uint256 tokenId_3, uint256 wantColorIndex ) public {}

- function colorChangeBetweenUser( address user1, address user2, uint256 token1, uint256 token2 ) public {}

- function getUserList() public view returns(address[] memory){}
  유저 리스트를 불러오는 함수

- function getCowardList() public {}
  coward 리스트를 반환하는 함수

- function checkUserHaveMinted(address \_userAddress) public view returns(bool){}
  민팅을 했는지 체크하는 함수

- function checkUserIsCoward(address \_userAddress) public view returns(bool){}
  coward 인지 체크하는 함수

- function \_beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual override(ERC721Enumerable) {}

- function \_afterTokenTransfer( address from, address to, uint256 tokenId ) internal virtual override(ERC721) {}

- function getTokens(address \_userAddress) public view returns (TokenData[] memory) {}
  보유하고 있는 토큰을 반환하는 함수

- function countTokenColor(string memory \_color) public view returns(uint256){}
  색깔별로 민팅된 갯수를 반환하는 함수

- function getColor(uint256 tokenId) public view returns (uint256) {}

- function withdraw() external onlyOwner {}

## 테스트 코드

truffle 환경에서 chai를 사용하여 테스트

#### case1 : 배포 뒤 각 값들이 정확하게 생성되었는지 점검

- 1.1. owner 주소가 정확한지
- 1.2. 토큰 이름
- 1.3. 토큰 심볼

#### case2 : 각 역할에 맞게 NFT 발행이 거부되는가

- 2.1. owner가 그냥 mint를 한 경우
- 2.2. 일반 사용자가 owner mint를 한 경우

#### case3 : 민팅이 문제없이 작동하는가

- 3.1. 사용자 민팅이 작동하는가
- 3.2. owner 민팅이 작동하는가
- 3.3. owner가 200개 넘게 민팅시 거부되는가

#### case4 : 일반 transfer가 제대로 작동하며 coward list에 등록되는가

#### case5 : 원하는 color minting이 제대로 작동하는가

- 5.1. 사용자인 경우
- 5.2. owner인 경우

#### case6 : 컬러 기반 토큰 교환이 제대로 이루어지는가 / 각자의 소유권이 인정되는지 보장할 필요

#### case7 : 같은 색 3개의 토큰으로 다른 색 토큰으로 교환이 제대로 이루어지는가?
