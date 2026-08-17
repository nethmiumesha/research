pragma solidity >=0.6.10 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract VestingEscrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event Fund(uint256 amount);
    event Claim(uint256 amount);
    event ToggleDisable(bool disabled);
    address public immutable token;
    address public immutable recipient;
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    bool public canDisable;
    uint256 public initialLocked;
    uint256 public vestedAtStart;
    uint256 public totalClaimed;
    uint256 public disabledAt;
    constructor(
        address token_,
        address recipient_,
        uint256 startTime_,
        uint256 endTime_,
        bool canDisable_
    ) public {
        token = token_;
        recipient = recipient_;
        startTime = startTime_;
        endTime = endTime_;
        canDisable = canDisable_;
    }
    function initialize(uint256 amount, uint256 vestedAtStart_) external {
        require(amount != 0 && amount >= vestedAtStart_, "Invalid amount or vestedAtStart");
        require(initialLocked == 0, "Already initialized");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        initialLocked = amount;
        vestedAtStart = vestedAtStart_;
        emit Fund(amount);
    }
    function vestedSupply() external view returns (uint256) {
        return _totalVestedOf(block.timestamp);
    }
    function lockedSupply() external view returns (uint256) {
        return initialLocked.sub(_totalVestedOf(block.timestamp));
    }
    function balanceOf(address account) external view returns (uint256) {
        if (account != recipient) {
            return 0;
        }
        return _totalVestedOf(block.timestamp).sub(totalClaimed);
    }
    function toggleDisable() external onlyOwner {
        require(canDisable, "Cannot disable");
        bool isDisabled = disabledAt == 0;
        if (isDisabled) {
            disabledAt = block.timestamp;
        } else {
            disabledAt = 0;
        }
        emit ToggleDisable(isDisabled);
    }
    function disableCanDisable() external onlyOwner {
        canDisable = false;
    }
    function claim() external nonReentrant {
        uint256 timestamp = disabledAt;
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }
        uint256 claimable = _totalVestedOf(timestamp).sub(totalClaimed);
        totalClaimed = totalClaimed.add(claimable);
        IERC20(token).safeTransfer(recipient, claimable);
        emit Claim(claimable);
    }
    function _totalVestedOf(uint256 timestamp) internal view returns (uint256) {
        uint256 start = startTime;
        uint256 end = endTime;
        uint256 locked = initialLocked;
        if (timestamp < start) {
            return 0;
        } else if (timestamp > end) {
            return locked;
        }
        uint256 vestedAtStart_ = vestedAtStart;
        return
            locked.sub(vestedAtStart_).mul(timestamp - start).div(end - start).add(vestedAtStart_);
    }
}