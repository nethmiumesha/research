pragma solidity ^0.5.16;
import "./RErc20.sol";
contract RErc20Immutable is RErc20 {
    constructor(address underlying_,
                IronControllerInterface ironController_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable admin_) public {
        admin = msg.sender;
        initialize(underlying_, ironController_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);
        admin = admin_;
    }
}