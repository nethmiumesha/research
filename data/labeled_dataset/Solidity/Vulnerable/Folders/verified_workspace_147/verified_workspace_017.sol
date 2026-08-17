pragma solidity ^0.8.0;
interface IStandardizedYieldExtended {
    function pricingInfo() external view returns (address refToken, bool refStrictlyEqual);
}