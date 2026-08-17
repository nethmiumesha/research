pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OkaYieldModuleBase} from "./base/OkaYieldModuleBase.sol";
import {ISafe} from "./interfaces/ISafe.sol";
contract OkaLidoYieldModule is OkaYieldModuleBase {
    constructor(
        address _okaOwner,
        address _feeReceiver,
        address _guardian,
        uint256 _harvestCooldown,
        uint256 _maxHarvestBps
    ) OkaYieldModuleBase(_okaOwner, _feeReceiver, _guardian, _harvestCooldown, _maxHarvestBps) {}
    function _harvestInternal(address safe, address token) internal override {
        uint256 currentBalance = IERC20(token).balanceOf(safe);
        uint256 checkpoint = lastCheckpoints[safe][token];
        if (checkpoint == 0) {
            emit HarvestSkipped(safe, token, SKIP_NO_CHECKPOINT);
            return;
        }
        if (currentBalance <= checkpoint) {
            emit HarvestSkipped(safe, token, SKIP_NO_YIELD);
            return;
        }
        uint256 yield_ = currentBalance - checkpoint;
        uint16 feeBps = vaultConfigs[safe].feeBps;
        uint256 fee = _calculateDefensiveFee(yield_, currentBalance, feeBps);
        if (fee == 0) {
            emit HarvestSkipped(safe, token, SKIP_ZERO_FEE);
            return;
        }
        uint256 checkpointBefore = lastCheckpoints[safe][token];
        uint256 checkpointAfter = currentBalance - fee;
        lastCheckpoints[safe][token] = checkpointAfter;
        totalFeeCollected[safe][token] += fee;
        harvestCount[safe] += 1;
        bytes memory data = abi.encodeCall(IERC20.transfer, (feeReceiver, fee));
        _executeFromModule(ISafe(safe), token, 0, data);
        emit Harvested(safe, token, yield_, fee, feeBps, checkpointBefore, checkpointAfter);
    }
}