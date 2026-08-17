pragma solidity ^0.6.10;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Ownable.sol";
contract LPStakingNFT is Ownable, ERC721 {
    using SafeMath for uint256;
    uint256 public tokenID;
    mapping(address => uint) private nftId;
    event MintedToken(address _staker, uint256 _tokenId, uint256 _time);
    event RevertCompleted(address _stakeholder, uint256 _tokenId, uint256 _revertNum, uint256 _time);
    constructor() Ownable() ERC721("NFY/ETH LP Staking NFT", "LPNFT") public {}
    function mint(address _minter) external onlyPlatform() {
        tokenID = tokenID.add(1);
        _safeMint(_minter, tokenID, '');
        nftId[_minter] = tokenID;
        emit MintedToken(_minter, tokenID, now);
    }
    function revertNftTokenId(address _stakeholder, uint _tokenId) external onlyPlatform() {
        require(ownerOf(_tokenId) == _stakeholder, "not owner of token");
        nftId[_stakeholder] = 0;
        emit RevertCompleted(_stakeholder, _tokenId, nftId[_stakeholder], now);
    }
    function nftTokenId(address _stakeholder) external view returns(uint id){
        if(nftId[_stakeholder] == 0 || balanceOf(_stakeholder) == 0){
            return 0;
        }
        else if(ownerOf(nftId[_stakeholder]) != _stakeholder) {
            return 0;
        }
        else {
            return nftId[_stakeholder];
        }
    }
    function burn(uint256 _token) external onlyPlatform() {
        _burn(_token);
    }
}