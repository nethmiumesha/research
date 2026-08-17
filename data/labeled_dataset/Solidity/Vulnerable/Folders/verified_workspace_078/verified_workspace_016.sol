pragma solidity ^0.6.12;
interface IRateModel {
    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) external view returns (uint);
    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) external view returns (uint);
}