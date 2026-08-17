pragma solidity ^0.8.4;
import '../interfaces/IOKLGDividendDistributor.sol';
import '../OKLGWithdrawable.sol';
contract OKLGRewardsTreasurySplitter is OKLGWithdrawable {
  address public rewards;
  uint8 public rewardsPercent = 100;
  IOKLGDividendDistributor rewardsContract;
  address public treasury;
  uint8 public treasuryPercent = 0;
  constructor(address _rewards, address _treasury) {
    rewards = _rewards;
    rewardsContract = IOKLGDividendDistributor(rewards);
    treasury = _treasury;
  }
  function setRewards(address _r) external onlyOwner {
    rewards = _r;
    rewardsContract = IOKLGDividendDistributor(rewards);
  }
  function setRewardsPercent(uint8 _p) external onlyOwner {
    require(_p + treasuryPercent <= 100, 'total percent must be <= 100');
    rewardsPercent = _p;
  }
  function setTreasury(address _t) external onlyOwner {
    treasury = _t;
  }
  function setTreasuryPercent(uint8 _p) external onlyOwner {
    require(_p + rewardsPercent <= 100, 'total percent must be <= 100');
    treasuryPercent = _p;
  }
  receive() external payable {
    if (treasuryPercent > 0) {
      payable(treasury).call{ value: (msg.value * treasuryPercent) / 100 }('');
    }
    if (rewardsPercent > 0) {
      rewardsContract.depositDividends{
        value: (msg.value * rewardsPercent) / 100
      }(0x0000000000000000000000000000000000000000, 0);
    }
  }
}