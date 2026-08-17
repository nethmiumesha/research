pragma solidity 0.5.4;
import { OmiseToken } from "./OmiseToken.sol";
contract ErroringOmiseToken is OmiseToken {
    function transfer(address, uint256) public {
        require(false);
    }
    function transferFrom(address, address, uint256) public {
        require(false);
    }
    function approve(address, uint256) public {
        require(false);
    }
}