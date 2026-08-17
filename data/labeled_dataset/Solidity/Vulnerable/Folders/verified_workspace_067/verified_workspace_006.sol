pragma solidity 0.5.11;
interface ICERC20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function comptroller() external view returns (address);
}