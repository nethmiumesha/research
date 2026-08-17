pragma solidity 0.5.10;
contract MockUniswapFactory {
    constructor () public {
    }
    address public exchangeTemplate;
    uint256 public tokenCount;
    function createExchange(address token) external returns (address exchange) {
        return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    }
    function getExchange(address token) external view returns (address exchange){
        return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    }
    function getToken(address exchange) external view returns (address token) {
        return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    }
    function getTokenWithId(uint256 tokenId) external view returns (address token) {
        return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    }
    function initializeFactory(address template) external {
    }
}