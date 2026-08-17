pragma solidity ^0.6.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Ownable.sol";
interface ILPStakingNFT {
    function nftTokenId(address _stakeholder) external view returns(uint id);
    function revertNftTokenId(address _stakeholder, uint _tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
contract LPStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct NFT {
        address _addressOfMinter;
        uint _LPDeposited;
        bool _inCirculation;
        uint _rewardDebt;
    }
    event StakeCompleted(address _staker, uint _amount, uint _tokenId, uint _totalStaked, uint _time);
    event PoolUpdated(uint _blocksRewarded, uint _amountRewarded, uint _time);
    event RewardsClaimed(address _staker, uint _rewardsClaimed, uint _tokenId, uint _time);
    event MintedToken(address _staker, uint256 _tokenId, uint256 _time);
    event EmergencyWithdrawOn(address _caller, bool _emergencyWithdraw, uint _time);
    event WithdrawCompleted(address _staker, uint _amount, uint _tokenId, uint _time);
    IERC20 public LPToken;
    IERC20 public NFYToken;
    ILPStakingNFT public StakingNFT;
    address public rewardPool;
    address public staking;
    uint public dailyReward;
    uint public accNfyPerShare;
    uint public lastRewardBlock;
    uint public totalStaked;
    bool public emergencyWithdraw = false;
    mapping(uint => NFT) public NFTDetails;
    constructor(address _LPToken, address _NFYToken, address _StakingNFT, address _staking, address _rewardPool, uint _dailyReward) Ownable() public {
        LPToken = IERC20(_LPToken);
        NFYToken = IERC20(_NFYToken);
        StakingNFT = ILPStakingNFT(_StakingNFT);
        staking = _staking;
        rewardPool = _rewardPool;
        lastRewardBlock = block.number;
        setDailyReward(_dailyReward);
        accNfyPerShare = 0;
    }
    function getRewardPerBlock() public view returns(uint) {
        return NFYToken.balanceOf(rewardPool).div(6500).div(10000).mul(dailyReward);
    }
    function setDailyReward(uint _dailyReward) public onlyOwner {
        dailyReward = _dailyReward;
    }
    function getNFTBalance(uint _tokenId) public view returns(uint _amountStaked) {
        return NFTDetails[_tokenId]._LPDeposited;
    }
    function checkIfNFTInCirculation(uint _tokenId) public view returns(bool _inCirculation) {
        return NFTDetails[_tokenId]._inCirculation;
    }
    function pendingRewards(uint _NFT) public view returns(uint) {
        NFT storage nft = NFTDetails[_NFT];
        uint256 _accNfyPerShare = accNfyPerShare;
        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 blocksToReward = block.number.sub(lastRewardBlock);
            uint256 nfyReward = blocksToReward.mul(getRewardPerBlock());
            _accNfyPerShare = _accNfyPerShare.add(nfyReward.mul(1e18).div(totalStaked));
        }
        return nft._LPDeposited.mul(_accNfyPerShare).div(1e18).sub(nft._rewardDebt);
    }
    function getTotalRewards(address _address) public view returns(uint) {
        uint totalRewards;
        for(uint i = 0; i < StakingNFT.balanceOf(_address); i++) {
            uint _rewardPerNFT = pendingRewards(StakingNFT.tokenOfOwnerByIndex(_address, i));
            totalRewards = totalRewards.add(_rewardPerNFT);
        }
        return totalRewards;
    }
    function getTotalBalance(address _address) public view returns(uint) {
        uint totalBalance;
        for(uint i = 0; i < StakingNFT.balanceOf(_address); i++) {
            uint _balancePerNFT = getNFTBalance(StakingNFT.tokenOfOwnerByIndex(_address, i));
            totalBalance = totalBalance.add(_balancePerNFT);
        }
        return totalBalance;
    }
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blocksToReward = block.number.sub(lastRewardBlock);
        uint256 nfyReward = blocksToReward.mul(getRewardPerBlock());
        NFYToken.transferFrom(rewardPool, address(this), nfyReward);
        accNfyPerShare = accNfyPerShare.add(nfyReward.mul(1e18).div(totalStaked));
        lastRewardBlock = block.number;
        emit PoolUpdated(blocksToReward, nfyReward, now);
    }
    function stakeLP(uint _amount) public {
        require(emergencyWithdraw == false, "emergency withdraw is on, cannot stake");
        require(_amount > 0, "Can not stake 0 LP tokens");
        require(LPToken.balanceOf(_msgSender()) >= _amount, "Do not have enough LP tokens to stake");
        updatePool();
        if(StakingNFT.nftTokenId(_msgSender()) == 0){
             addStakeholder(_msgSender());
        }
        NFT storage nft = NFTDetails[StakingNFT.nftTokenId(_msgSender())];
        if(nft._LPDeposited > 0) {
            uint _pendingRewards = nft._LPDeposited.mul(accNfyPerShare).div(1e18).sub(nft._rewardDebt);
            if(_pendingRewards > 0) {
                NFYToken.transfer(_msgSender(), _pendingRewards);
                emit RewardsClaimed(_msgSender(), _pendingRewards, StakingNFT.nftTokenId(_msgSender()), now);
            }
        }
        LPToken.transferFrom(_msgSender(), address(this), _amount);
        nft._LPDeposited = nft._LPDeposited.add(_amount);
        totalStaked = totalStaked.add(_amount);
        nft._rewardDebt = nft._LPDeposited.mul(accNfyPerShare).div(1e18);
        emit StakeCompleted(_msgSender(), _amount, StakingNFT.nftTokenId(_msgSender()), nft._LPDeposited, now);
    }
    function addStakeholder(address _stakeholder) private {
        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("mint(address)", _stakeholder));
        require(success == true, "Mint call failed");
        NFTDetails[StakingNFT.nftTokenId(_msgSender())]._addressOfMinter = _stakeholder;
        NFTDetails[StakingNFT.nftTokenId(_msgSender())]._inCirculation = true;
    }
    function addStakeholderExternal(address _stakeholder) external onlyPlatform() {
        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("mint(address)", _stakeholder));
        require(success == true, "Mint call failed");
        NFTDetails[StakingNFT.nftTokenId(_stakeholder)]._addressOfMinter = _stakeholder;
        NFTDetails[StakingNFT.nftTokenId(_stakeholder)]._inCirculation = true;
    }
    function claimRewards(uint _tokenId) public {
        require(StakingNFT.ownerOf(_tokenId) == _msgSender(), "User is not owner of token");
        require(NFTDetails[_tokenId]._inCirculation == true, "Stake has already been withdrawn");
        updatePool();
        NFT storage nft = NFTDetails[_tokenId];
        uint _pendingRewards = nft._LPDeposited.mul(accNfyPerShare).div(1e18).sub(nft._rewardDebt);
        require(_pendingRewards > 0, "No rewards to claim!");
        NFYToken.transfer(_msgSender(), _pendingRewards);
        nft._rewardDebt = nft._LPDeposited.mul(accNfyPerShare).div(1e18);
        emit RewardsClaimed(_msgSender(), _pendingRewards, _tokenId, now);
    }
    function claimAllRewards() public {
        require(StakingNFT.balanceOf(_msgSender()) > 0, "User has no stake");
        for(uint i = 0; i < StakingNFT.balanceOf(_msgSender()); i++) {
            uint _currentNFT = StakingNFT.tokenOfOwnerByIndex(_msgSender(), i);
            claimRewards(_currentNFT);
        }
    }
    function unstakeLP(uint _tokenId) public {
        require(emergencyWithdraw == true, "Can not withdraw");
        require(StakingNFT.ownerOf(_tokenId) == _msgSender(), "User is not owner of token");
        require(NFTDetails[_tokenId]._inCirculation == true, "Stake has already been withdrawn");
        updatePool();
        NFT storage nft = NFTDetails[_tokenId];
        uint _pendingRewards = nft._LPDeposited.mul(accNfyPerShare).div(1e18).sub(nft._rewardDebt);
        uint amountStaked = getNFTBalance(_tokenId);
        uint beingWithdrawn = nft._LPDeposited;
        nft._LPDeposited = 0;
        nft._inCirculation = false;
        totalStaked = totalStaked.sub(beingWithdrawn);
        StakingNFT.revertNftTokenId(_msgSender(), _tokenId);
        (bool success, bytes memory data) = staking.call(abi.encodeWithSignature("burn(uint256)", _tokenId));
        require(success == true, "burn call failed");
        LPToken.transfer(_msgSender(), amountStaked);
        NFYToken.transfer(_msgSender(), _pendingRewards);
        emit WithdrawCompleted(_msgSender(), amountStaked, _tokenId, now);
        emit RewardsClaimed(_msgSender(), _pendingRewards, _tokenId, now);
    }
    function unstakeAll() public {
        require(StakingNFT.balanceOf(_msgSender()) > 0, "User has no stake");
        while(StakingNFT.balanceOf(_msgSender()) > 0) {
            uint _currentNFT = StakingNFT.tokenOfOwnerByIndex(_msgSender(), 0);
            unstakeLP(_currentNFT);
        }
    }
    function incrementNFTValue (uint _tokenId, uint _amount) external onlyPlatform() {
        require(checkIfNFTInCirculation(_tokenId) == true, "Token not in circulation");
        updatePool();
        NFT storage nft = NFTDetails[_tokenId];
        if(nft._LPDeposited > 0) {
            uint _pendingRewards = nft._LPDeposited.mul(accNfyPerShare).div(1e18).sub(nft._rewardDebt);
            if(_pendingRewards > 0) {
                NFYToken.transfer(StakingNFT.ownerOf(_tokenId), _pendingRewards);
                emit RewardsClaimed(StakingNFT.ownerOf(_tokenId), _pendingRewards, _tokenId, now);
            }
        }
        NFTDetails[_tokenId]._LPDeposited =  NFTDetails[_tokenId]._LPDeposited.add(_amount);
        nft._rewardDebt = nft._LPDeposited.mul(accNfyPerShare).div(1e18);
    }
    function decrementNFTValue (uint _tokenId, uint _amount) external onlyPlatform() {
        require(checkIfNFTInCirculation(_tokenId) == true, "Token not in circulation");
        require(getNFTBalance(_tokenId) >= _amount, "Not enough stake in NFT");
        updatePool();
        NFT storage nft = NFTDetails[_tokenId];
        if(nft._LPDeposited > 0) {
            uint _pendingRewards = nft._LPDeposited.mul(accNfyPerShare).div(1e18).sub(nft._rewardDebt);
            if(_pendingRewards > 0) {
                NFYToken.transfer(StakingNFT.ownerOf(_tokenId), _pendingRewards);
                emit RewardsClaimed(StakingNFT.ownerOf(_tokenId), _pendingRewards, _tokenId, now);
            }
        }
        NFTDetails[_tokenId]._LPDeposited =  NFTDetails[_tokenId]._LPDeposited.sub(_amount);
        nft._rewardDebt = nft._LPDeposited.mul(accNfyPerShare).div(1e18);
    }
    function turnEmergencyWithdrawOn() public onlyOwner() {
        require(emergencyWithdraw == false, "emergency withdrawing already allowed");
        emergencyWithdraw = true;
        emit EmergencyWithdrawOn(_msgSender(), emergencyWithdraw, now);
    }
}