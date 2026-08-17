pragma solidity 0.5.4;
import { TestToken } from "./TestToken.sol";
contract ErroringToken is TestToken {
    function transfer(address, uint256) public returns (bool) {
        return false;
    }
    function transferFrom(address, address, uint256) public returns (bool) {
        return false;
    }
    function approve(address, uint256) public returns (bool) {
        return false;
    }
}