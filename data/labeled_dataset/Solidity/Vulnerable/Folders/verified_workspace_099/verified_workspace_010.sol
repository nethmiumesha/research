pragma solidity ^0.6.11;
import "../TroveManager.sol";
import "../BorrowerOperations.sol";
import "../ActivePool.sol";
import "../DefaultPool.sol";
import "../StabilityPool.sol";
import "../CollSurplusPool.sol";
import "../LUSDToken.sol";
import "./PriceFeedTestnet.sol";
import "../SortedTroves.sol";
import "./EchidnaProxy.sol";
    function echidna_trove_properties() public view returns(bool) {
        address currentTrove = sortedTroves.getFirst();
        while (currentTrove != address(0)) {
            if (TroveManager.Status(troveManager.getTroveStatus(currentTrove)) != TroveManager.Status.active) {
                return false;
            }
            if (troveManager.getTroveDebt(currentTrove) < LUSD_GAS_COMPENSATION) {
                return false;
            }
            if (troveManager.getTroveStake(currentTrove) == 0) {
                return false;
            }
            currentTrove = sortedTroves.getNext(currentTrove);
        }
        return true;
    }
    function echidna_ETH_balances() public view returns(bool) {
        if (address(troveManager).balance > 0) {
            return false;
        }
        if (address(borrowerOperations).balance > 0) {
            return false;
        }
        if (address(activePool).balance != activePool.getETH()) {
            return false;
        }
        if (address(defaultPool).balance != defaultPool.getETH()) {
            return false;
        }
        if (address(stabilityPool).balance != stabilityPool.getETH()) {
            return false;
        }
        if (address(lusdToken).balance > 0) {
            return false;
        }
        if (address(priceFeedTestnet).balance > 0) {
            return false;
        }
        if (address(sortedTroves).balance > 0) {
            return false;
        }
        return true;
    }
    function echidna_price() public view returns(bool) {
        uint price = priceFeedTestnet.getPrice();
        if (price == 0) {
            return false;
        }
        return true;
    }
    function echidna_LUSD_global_balances() public view returns(bool) {
        uint totalSupply = lusdToken.totalSupply();
        uint gasPoolBalance = lusdToken.balanceOf(GAS_POOL_ADDRESS);
        uint activePoolBalance = activePool.getLUSDDebt();
        uint defaultPoolBalance = defaultPool.getLUSDDebt();
        if (totalSupply != activePoolBalance + defaultPoolBalance) {
            return false;
        }
        uint stabilityPoolBalance = stabilityPool.getTotalLUSDDeposits();
        address currentTrove = sortedTroves.getFirst();
        uint trovesBalance;
        while (currentTrove != address(0)) {
            trovesBalance += lusdToken.balanceOf(address(currentTrove));
            currentTrove = sortedTroves.getNext(currentTrove);
        }
        if (totalSupply <= stabilityPoolBalance + trovesBalance + gasPoolBalance) {
            return false;
        }
        return true;
    }
}