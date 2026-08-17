pragma solidity ^0.6.12;
interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }
    function priceOf(address asset) external view returns (uint);
    function pricesOf(address[] memory assets) external view returns (uint[] memory);
    function getUnderlyingPrice(address qToken) external view returns (uint);
    function getUnderlyingPrices(address[] memory qTokens) external view returns (uint[] memory);
    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
}