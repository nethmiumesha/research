pragma solidity ^0.8.4;
import "./MockEthPCVDeposit.sol";
contract MockEthUniswapPCVDeposit is MockEthPCVDeposit {
    address public pair;
	constructor(address _pair) MockEthPCVDeposit(payable(this)) {
        pair = _pair;
    }
}