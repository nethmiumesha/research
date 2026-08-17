pragma solidity ^0.6.12;
interface IPresaleLocker {
    function setPresale(address _presaleContract) external;
    function setPresaleEndTime(uint endTime) external;
    function balanceOf(address account) external view returns (uint);
    function withdrawableBalanceOf(address account) external view returns (uint);
    function depositBehalf(address account, uint balance) external;
    function withdraw(uint amount) external;
    function withdrawAll() external;
    function recoverToken(address tokenAddress, uint tokenAmount) external;
}