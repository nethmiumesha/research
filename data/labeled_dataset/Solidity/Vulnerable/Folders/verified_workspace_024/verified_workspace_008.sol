pragma solidity ^0.8.4;
import "../IPCVDepositBalances.sol";
import "../../Constants.sol";
import "../../refs/CoreRef.sol";
contract StaticPCVDepositWrapper is IPCVDepositBalances, CoreRef {
    event BalanceUpdate(uint256 oldBalance, uint256 newBalance);
    event FeiBalanceUpdate(uint256 oldFeiBalance, uint256 newFeiBalance);
    uint256 public override balance;
    uint256 public feiReportBalance;
    constructor(address _core, uint256 _balance, uint256 _feiBalance) CoreRef(_core) {
        balance = _balance;
        feiReportBalance = _feiBalance;
    }
    function setBalance(uint256 newBalance) external onlyGovernor {
        uint256 oldBalance = balance;
        balance = newBalance;
        emit BalanceUpdate(oldBalance, newBalance);
    }
    function setFeiReportBalance(uint256 newFeiBalance) external onlyGovernor {
        uint256 oldFeiBalance = feiReportBalance;
        feiReportBalance = newFeiBalance;
        emit BalanceUpdate(oldFeiBalance, newFeiBalance);
    }
    function resistantBalanceAndFei() public view override returns (uint256, uint256) {
        return (balance, feiReportBalance);
    }
    function balanceReportedIn() public pure override returns (address) {
        return Constants.USD;
    }
}