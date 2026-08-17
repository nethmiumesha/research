pragma solidity ^0.8.6;
import "../../contracts/EIP20NonStandardInterface.sol";
contract Fauceteer {
    function drip(EIP20NonStandardInterface token) public {
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "Fauceteer is empty");
        token.transfer(msg.sender, balance / 10000);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    success := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        require(success, "Transfer returned false.");
    }
}