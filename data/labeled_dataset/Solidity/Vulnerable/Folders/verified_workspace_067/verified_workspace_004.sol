pragma solidity 0.5.11;
import "./VaultStorage.sol";
contract VaultInitializer is VaultStorage {
    function initialize(address _priceProvider, address _ousd)
        external
        onlyGovernor
        initializer
    {
        require(_priceProvider != address(0), "PriceProvider address is zero");
        require(_ousd != address(0), "oUSD address is zero");
        oUSD = OUSD(_ousd);
        priceProvider = _priceProvider;
        rebasePaused = false;
        capitalPaused = true;
        redeemFeeBps = 0;
        vaultBuffer = 0;
        autoAllocateThreshold = 25000e18;
        rebaseThreshold = 1000e18;
    }
}