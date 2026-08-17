pragma solidity 0.5.13;
import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "hardhat/console.sol";
import '../interfaces/IRCProxyXdai.sol';
import '../interfaces/IRCMarket.sol';
contract RCNftHubXdai is Ownable, ERC721Full
{
    mapping (address => bool) public isMarket;
    mapping(uint256 => address) public marketTracker;
    address public factoryAddress;
    constructor(address _factoryAddress) ERC721Full("RealityCards", "RC") public {
        setFactoryAddress(_factoryAddress);
    }
    function addMarket(address _newMarket) external returns(bool) {
        require(msg.sender == factoryAddress, "Not factory");
        isMarket[_newMarket] = true;
        return true;
    }
    function setFactoryAddress(address _newAddress) onlyOwner public {
        factoryAddress = _newAddress;
    }
    function mintNft(address _originalOwner, uint256 _tokenId, string calldata _tokenURI) external returns(bool) {
        require(msg.sender == factoryAddress, "Not factory");
        _mint(_originalOwner, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        marketTracker[_tokenId] = _originalOwner;
        return true;
    }
    function transferNft(address _currentOwner, address _newOwner, uint256 _tokenId) external returns(bool) {
        require(isMarket[msg.sender], "Not market");
        _transferFrom(_currentOwner, _newOwner, _tokenId);
        return true;
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        IRCMarket market = IRCMarket(marketTracker[tokenId]);
        require(market.state() == 3, "Incorrect state");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        IRCMarket market = IRCMarket(marketTracker[tokenId]);
        require(market.state() == 3, "Incorrect state");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _transferFrom(from, to, tokenId);
        _data;
    }
}