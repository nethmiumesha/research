pragma solidity ^0.8.6;
import "../../contracts/InterestRateModel.sol";
contract InterestRateModelHarness is InterestRateModel {
    uint public constant opaqueBorrowFailureCode = 20;
    bool public failBorrowRate;
    uint public borrowRate;
    constructor(uint borrowRate_) {
        borrowRate = borrowRate_;
    }
    function setFailBorrowRate(bool failBorrowRate_) public {
        failBorrowRate = failBorrowRate_;
    }
    function setBorrowRate(uint borrowRate_) public {
        borrowRate = borrowRate_;
    }
    function getBorrowRate(uint _cash, uint _borrows, uint _reserves) override public view returns (uint) {
        _cash;
        _borrows;
        _reserves;
        require(!failBorrowRate, "INTEREST_RATE_MODEL_ERROR");
        return borrowRate;
    }
    function getSupplyRate(uint _cash, uint _borrows, uint _reserves, uint _reserveFactor) override external view returns (uint) {
        _cash;
        _borrows;
        _reserves;
        return borrowRate * (1 - _reserveFactor);
    }
}