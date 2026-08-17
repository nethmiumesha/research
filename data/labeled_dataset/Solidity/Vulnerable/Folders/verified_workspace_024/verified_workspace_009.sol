pragma solidity ^0.8.0;
import "../PCVDeposit.sol";
import "../../Constants.sol";
import "@openzeppelin/contracts/utils/Address.sol";
abstract contract WethPCVDeposit is PCVDeposit {
    receive() external payable virtual {}
    function wrapETH() public {
        uint256 ethBalance = address(this).balance;
        if (ethBalance != 0) {
            Constants.WETH.deposit{value: ethBalance}();
        }
    }
    function deposit() external virtual override {
        wrapETH();
    }
    function withdrawETH(address payable to, uint256 amountOut)
        external
        override
        onlyPCVController
    {
        Constants.WETH.withdraw(amountOut);
        Address.sendValue(to, amountOut);
        emit WithdrawETH(msg.sender, to, amountOut);
    }
}