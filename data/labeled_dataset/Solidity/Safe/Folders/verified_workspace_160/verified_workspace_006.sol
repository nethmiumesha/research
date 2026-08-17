pragma solidity 0.5.10;
contract UniswapFactoryInterface {
    address public exchangeTemplate;
    uint256 public tokenCount;
    function createExchange(address token) external returns (address exchange);
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    function initializeFactory(address template) external;
}