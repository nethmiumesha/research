pragma solidity 0.8.6;
import "../../libraries/Margin.sol";
contract TestMargin {
    using Margin for Margin.Data;
    using Margin for mapping(address => Margin.Data);
    mapping(address => Margin.Data) public margins;
    function margin() public view returns (Margin.Data memory) {
        return margins[msg.sender];
    }
    function shouldDeposit(uint256 delRisky, uint256 delStable) public returns (Margin.Data memory) {
        uint128 preX = margins[msg.sender].balanceRisky;
        uint128 preY = margins[msg.sender].balanceStable;
        margins[msg.sender].deposit(delRisky, delStable);
        assert(preX + delRisky >= margins[msg.sender].balanceRisky);
        assert(preY + delStable >= margins[msg.sender].balanceStable);
        return margins[msg.sender];
    }
    function shouldWithdraw(uint256 delRisky, uint256 delStable) public returns (Margin.Data memory) {
        uint128 preX = margins[msg.sender].balanceRisky;
        uint128 preY = margins[msg.sender].balanceStable;
        margins[msg.sender] = margins.withdraw(delRisky, delStable);
        assert(preX - delRisky >= margins[msg.sender].balanceRisky);
        assert(preY - delStable >= margins[msg.sender].balanceStable);
        return margins[msg.sender];
    }
}