pragma solidity ^0.5.16;
import "./SafeMath.sol";
import "./BEP20Interface.sol";
import "./Ownable.sol";
contract VTreasury is Ownable {
    using SafeMath for uint256;
    event WithdrawTreasuryBEP20(address tokenAddress, uint256 withdrawAmount, address withdrawAddress);
    event WithdrawTreasuryBNB(uint256 withdrawAmount, address withdrawAddress);
    function () external payable {}
    function withdrawTreasuryBEP20(
      address tokenAddress,
      uint256 withdrawAmount,
      address withdrawAddress
    ) external onlyOwner {
        uint256 actualWithdrawAmount = withdrawAmount;
        uint256 treasuryBalance = BEP20Interface(tokenAddress).balanceOf(address(this));
        if (withdrawAmount > treasuryBalance) {
            actualWithdrawAmount = treasuryBalance;
        }
        BEP20Interface(tokenAddress).transfer(withdrawAddress, actualWithdrawAmount);
        emit WithdrawTreasuryBEP20(tokenAddress, actualWithdrawAmount, withdrawAddress);
    }
    function withdrawTreasuryBNB(
      uint256 withdrawAmount,
      address payable withdrawAddress
    ) external payable onlyOwner {
        uint256 actualWithdrawAmount = withdrawAmount;
        uint256 bnbBalance = address(this).balance;
        if (withdrawAmount > bnbBalance) {
            actualWithdrawAmount = bnbBalance;
        }
        withdrawAddress.transfer(actualWithdrawAmount);
        emit WithdrawTreasuryBNB(actualWithdrawAmount, withdrawAddress);
    }
}