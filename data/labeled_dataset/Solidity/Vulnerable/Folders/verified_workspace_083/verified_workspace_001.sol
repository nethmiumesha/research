pragma solidity 0.8.0;
interface Ivesting {
  function initialize
   (
    address _token,
    address _owner,
    uint256 _startInDays,
    uint256 _durationInDays,
    uint256 _cliffInTenThousands,
    uint256 _cliffDelayInDays,
    uint256 _exp
   )
    external;
  function depositForCrowd(address[] memory _recipient, uint256[] memory _amount) external;
  function depositAllFor(address _recipient) external;
  function retrieve() external;
  function retrieveFor(address[] memory accounts) external;
  function decreaseVesting(address _account, uint256 amount) external;
  function getTotalDeposit(address _account) external view returns(uint256);
  function getRetrievablePercentage() external view returns(uint256);
  function balanceOf(address account) external view returns(uint256);
  function getRetrievableAmount(address _account) external view returns(uint256);
  function getTotalVestingBalance(address _account) external view returns(uint256);
  function depositFor(address _recipient, uint256 _amount) external;
}