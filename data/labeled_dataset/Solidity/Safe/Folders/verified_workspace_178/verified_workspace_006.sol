pragma solidity ^0.6.6;
interface IOneSwapPool {
    event Mint(address indexed sender, uint stockAndMoneyAmount, address indexed to);
    event Burn(address indexed sender, uint stockAndMoneyAmount, address indexed to);
    event Sync(uint reserveStockAndMoney);
    function getReserves() external view returns (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID);
    function getBooked() external view returns (uint112 bookedStock, uint112 bookedMoney, uint32 firstBuyID);
    function stock() external view returns (address);
    function money() external view returns (address);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint stockAmount, uint moneyAmount);
    function skim(address to) external;
    function sync() external;
}
interface IOneSwapPair {
    event NewLimitOrder(uint data);
    event NewMarketOrder(uint data);
    event OrderChanged(uint data);
    event DealWithPool(uint data);
    event RemoveOrder(uint data);
    function getPrices() external view returns (
        uint firstSellPriceNumerator,
        uint firstSellPriceDenominator,
        uint firstBuyPriceNumerator,
        uint firstBuyPriceDenominator,
        uint poolPriceNumerator,
        uint poolPriceDenominator);
    function getOrderList(bool isBuy, uint32 id, uint32 maxCount) external view returns (uint[] memory);
    function removeOrder(bool isBuy, uint32 id, uint72 positionID) external;
    function addLimitOrder(bool isBuy, address sender, uint64 amount, uint32 price32, uint32 id, uint72 prevKey) external payable;
    function addMarketOrder(address inputToken, address sender, uint112 inAmount, bool isLastSwap) external payable returns (uint);
    function calcStockAndMoney(uint64 amount, uint32 price32) external view returns (uint stockAmount, uint moneyAmount);
}