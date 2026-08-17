pragma solidity 0.5.16;
import "openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol";
import "./BankConfig.sol";
contract SimpleBankConfig is BankConfig, Ownable {
    struct GoblinConfig {
        bool isGoblin;
        bool acceptDebt;
        uint256 workFactor;
        uint256 killFactor;
    }
    uint256 public minDebtSize;
    uint256 public interestRate;
    uint256 public getReservePoolBps;
    uint256 public getKillBps;
    mapping (address => GoblinConfig) public goblins;
    constructor(
        uint256 _minDebtSize,
        uint256 _interestRate,
        uint256 _reservePoolBps,
        uint256 _killBps
    ) public {
        setParams(_minDebtSize, _interestRate, _reservePoolBps, _killBps);
    }
    function setParams(
        uint256 _minDebtSize,
        uint256 _interestRate,
        uint256 _reservePoolBps,
        uint256 _killBps
    ) public onlyOwner {
        minDebtSize = _minDebtSize;
        interestRate = _interestRate;
        getReservePoolBps = _reservePoolBps;
        getKillBps = _killBps;
    }
    function setGoblin(
        address goblin,
        bool _isGoblin,
        bool _acceptDebt,
        uint256 _workFactor,
        uint256 _killFactor
    ) public onlyOwner {
        goblins[goblin] = GoblinConfig({
            isGoblin: _isGoblin,
            acceptDebt: _acceptDebt,
            workFactor: _workFactor,
            killFactor: _killFactor
        });
    }
    function getInterestRate(uint256 , uint256 ) external view returns (uint256) {
        return interestRate;
    }
    function isGoblin(address goblin) external view returns (bool) {
        return goblins[goblin].isGoblin;
    }
    function acceptDebt(address goblin) external view returns (bool) {
        require(goblins[goblin].isGoblin, "!goblin");
        return goblins[goblin].acceptDebt;
    }
    function workFactor(address goblin, uint256 ) external view returns (uint256) {
        require(goblins[goblin].isGoblin, "!goblin");
        return goblins[goblin].workFactor;
    }
    function killFactor(address goblin, uint256 ) external view returns (uint256) {
        require(goblins[goblin].isGoblin, "!goblin");
        return goblins[goblin].killFactor;
    }
}