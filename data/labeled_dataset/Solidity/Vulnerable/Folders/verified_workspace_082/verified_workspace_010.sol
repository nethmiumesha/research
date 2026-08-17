pragma solidity ^0.5.16;
import "../../contracts/EIP20NonStandardInterface.sol";
contract Fauceteer {
    function drip(EIP20NonStandardInterface token) public {
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "Fauceteer is empty");
        token.transfer(msg.sender, tokenBalance / 10000);
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