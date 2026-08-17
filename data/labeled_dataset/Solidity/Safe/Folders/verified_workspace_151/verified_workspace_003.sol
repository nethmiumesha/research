pragma solidity ^0.4.23;
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
contract AuctionBase is Pausable {
  using SafeMath for uint256;
  mapping(uint256 => address) public auctionIdToSeller;
  uint256 public nextAuctionId = 1;
  modifier onlySeller(uint256 auctionId) {
    require(msg.sender == auctionIdToSeller[auctionId]);
    _;
  }
  event AuctionCreated(address indexed createdBy, uint256 indexed auctionId);
  function createEmptyAuction() internal returns (uint256) {
    uint256 thisAuctionId = nextAuctionId;
    nextAuctionId = nextAuctionId.add(1);
    auctionIdToSeller[thisAuctionId] = msg.sender;
    emit AuctionCreated(msg.sender, thisAuctionId);
    return thisAuctionId;
  }
  function transferWinnings(address recipient, uint256 auctionId) internal;
}
contract FeeCollector is Ownable {
  using SafeMath for uint256;
  uint256 feeBalance = 0;
  modifier requiresFee(uint256 feeAmount) {
    require(msg.value >= feeAmount);
    feeBalance = feeBalance.add(feeAmount);
    msg.sender.transfer(msg.value.sub(feeAmount));
    _;
  }
  event FeesWithdrawn(address indexed owner, uint256 indexed withdrawalAmount);
  function withdrawFees() external onlyOwner {
    uint256 feeAmountWithdrawn = feeBalance;
    feeBalance = 0;
    owner.transfer(feeAmountWithdrawn);
    emit FeesWithdrawn(owner, feeAmountWithdrawn);
  }
}
contract DescendingPriceAuction is AuctionBase, FeeCollector {
  using SafeMath for uint256;
  mapping(uint256 => uint256) public auctionIdToStartPrice;
  mapping(uint256 => uint256) public auctionIdToPriceFloor;
  mapping(uint256 => uint256) public auctionIdToStartBlock;
  mapping(uint256 => uint256) public auctionIdToPriceFloorBlock;
  mapping(uint256 => bool) public auctionIdToAcceptingBids;
  modifier onlyAcceptingBids(uint256 auctionId) {
    require(auctionIdToAcceptingBids[auctionId]);
    _;
  }
  function bid(uint256 auctionId) whenNotPaused onlyAcceptingBids(auctionId) external payable {
    require(msg.sender != 0x0);
    uint256 currentPrice = getCurrentPrice(auctionId);
    require(msg.value >= currentPrice);
    auctionIdToAcceptingBids[auctionId] = false;
    transferWinnings(msg.sender, auctionId);
    uint256 overbidAmount = msg.value.sub(currentPrice);
    if (overbidAmount > 0) {
      msg.sender.transfer(overbidAmount);
    }
    auctionIdToSeller[auctionId].transfer(currentPrice);
  }
  function cancel(uint256 auctionId) whenNotPaused public onlySeller(auctionId) {
    transferWinnings(auctionIdToSeller[auctionId], auctionId);
    auctionIdToAcceptingBids[auctionId] = false;
  }
  function getCurrentPrice(uint256 auctionId) public view returns (uint256) {
    uint256 priceFloorBlock = auctionIdToPriceFloorBlock[auctionId];
    uint256 priceFloor = auctionIdToPriceFloor[auctionId];
    if (block.number >= priceFloorBlock) {
      return priceFloor;
    }
    uint256 startBlock = auctionIdToStartBlock[auctionId];
    uint256 startPrice = auctionIdToStartPrice[auctionId];
    uint256 priceDifference = startPrice.sub(priceFloor);
    uint256 blockDifference = priceFloorBlock.sub(startBlock);
    uint256 numberOfBlocksElapsed = block.number.sub(startBlock);
    uint256 priceDecrease = numberOfBlocksElapsed.mul(priceDifference.div(blockDifference));
    return startPrice.sub(priceDecrease);
  }
  function setAuctionPricing(uint256 startPrice, uint256 priceFloor, uint256 duration, uint256 auctionId) requiresFee(startPrice.div(50)) internal {
    require(startPrice > 0 && priceFloor < startPrice && priceFloor >= 0 && duration > 0);
    auctionIdToStartBlock[auctionId] = block.number;
    auctionIdToStartPrice[auctionId] = startPrice;
    auctionIdToPriceFloor[auctionId] = priceFloor;
    auctionIdToPriceFloorBlock[auctionId] = block.number.add(duration);
    auctionIdToAcceptingBids[auctionId] = true;
  }
}
contract Whitelistable is Ownable {
  mapping(address => bool) public whitelist;
  event AddToWhitelist(address _address);
  event RemoveFromWhitelist(address _address);
  modifier isWhitelisted(address _addr) {
    require(inWhitelist(_addr));
    _;
  }
  function inWhitelist(address _address) public view returns (bool) {
    return whitelist[_address];
  }
  function addToWhitelist(address _address) public onlyOwner returns (bool) {
    if (whitelist[_address]) {
      return false;
    }
    whitelist[_address] = true;
    emit AddToWhitelist(_address);
    return true;
  }
  function removeFromWhitelist(address _address) public onlyOwner returns (bool) {
    if (!whitelist[_address]) {
      return false;
    }
    whitelist[_address] = false;
    emit RemoveFromWhitelist(_address);
    return true;
  }
}
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}
contract ERC721Auction is AuctionBase, Whitelistable {
  mapping(address => mapping(uint256 => uint256)) assetContractToAssetIdToAuctionId;
  mapping(uint256 => address) public auctionIdToAssetContract;
  mapping(uint256 => uint256) public auctionIdToAssetId;
  function setAuctionAsset(address assetContract, uint256 assetId, uint256 auctionId) isWhitelisted(assetContract) internal {
    require(auctionId != 0);
    require(assetContractToAssetIdToAuctionId[assetContract][assetId] == 0);
    auctionIdToAssetContract[auctionId] = assetContract;
    auctionIdToAssetId[auctionId] = assetId;
    assetContractToAssetIdToAuctionId[assetContract][assetId] = auctionId;
    escrowAsset(msg.sender, assetContract, assetId);
  }
  function transferWinnings(address recipient, uint256 auctionId) internal {
    require(auctionId != 0);
    require(auctionHasAsset(auctionId));
    address assetContractAddress = auctionIdToAssetContract[auctionId];
    ERC721Basic assetContract = ERC721Basic(assetContractAddress);
    uint256 assetId = auctionIdToAssetId[auctionId];
    assetContractToAssetIdToAuctionId[assetContractAddress][assetId] = 0;
    assetContract.safeTransferFrom(address(this), recipient, assetId);
  }
  function escrowAsset(address seller, address auctionAssetContract, uint256 assetId) private {
    ERC721Basic assetContract = ERC721Basic(auctionAssetContract);
    assetContract.transferFrom(seller, this, assetId);
  }
  function auctionHasAsset(uint256 auctionId) private view returns (bool) {
    address assetContractForAuction = auctionIdToAssetContract[auctionId];
    uint256 assetId = auctionIdToAssetId[auctionId];
    uint256 auctionThatCurrentlyOwnsAsset = assetContractToAssetIdToAuctionId[assetContractForAuction][assetId];
    return(auctionThatCurrentlyOwnsAsset == auctionId && auctionThatCurrentlyOwnsAsset != 0);
  }
}
contract DescendingPriceERC721Auction is DescendingPriceAuction, ERC721Auction {
  function createAuction(
    uint256 startPrice,
    uint256 priceFloor,
    uint256 duration,
    address assetAddress,
    uint256 assetId) whenNotPaused public payable returns (uint256)
    {
    uint256 auctionId = createEmptyAuction();
    setAuctionPricing(startPrice, priceFloor, duration, auctionId);
    setAuctionAsset(assetAddress, assetId, auctionId);
    return auctionId;
  }
}