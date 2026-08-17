pragma solidity ^0.5.16;
import "./Owned.sol";
import "./State.sol";
import "./interfaces/ISynthetixState.sol";
import "./SafeDecimalMath.sol";
contract SynthetixState is Owned, State, ISynthetixState {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    struct IssuanceData {
        uint initialDebtOwnership;
        uint debtEntryIndex;
    }
    mapping(address => IssuanceData) public issuanceData;
    uint public totalIssuerCount;
    uint[] public debtLedger;
    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}
    function setCurrentIssuanceData(address account, uint initialDebtOwnership) external onlyAssociatedContract {
        issuanceData[account].initialDebtOwnership = initialDebtOwnership;
        issuanceData[account].debtEntryIndex = debtLedger.length;
    }
    function clearIssuanceData(address account) external onlyAssociatedContract {
        delete issuanceData[account];
    }
    function incrementTotalIssuerCount() external onlyAssociatedContract {
        totalIssuerCount = totalIssuerCount.add(1);
    }
    function decrementTotalIssuerCount() external onlyAssociatedContract {
        totalIssuerCount = totalIssuerCount.sub(1);
    }
    function appendDebtLedgerValue(uint value) external onlyAssociatedContract {
        debtLedger.push(value);
    }
    function debtLedgerLength() external view returns (uint) {
        return debtLedger.length;
    }
    function lastDebtLedgerEntry() external view returns (uint) {
        return debtLedger[debtLedger.length - 1];
    }
    function hasIssued(address account) external view returns (bool) {
        return issuanceData[account].initialDebtOwnership > 0;
    }
}