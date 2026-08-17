pragma solidity ^0.8.4;
import "./Timed.sol";
import "./ILinearTokenTimelock.sol";
contract LinearTokenTimelock is ILinearTokenTimelock, Timed {
    IERC20 public override lockedToken;
    address public override beneficiary;
    address public override pendingBeneficiary;
    uint256 public override initialBalance;
    uint256 internal lastBalance;
    constructor(
        address _beneficiary,
        uint256 _duration,
        address _lockedToken
    ) Timed(_duration) {
        require(_duration != 0, "LinearTokenTimelock: duration is 0");
        require(
            _beneficiary != address(0),
            "LinearTokenTimelock: Beneficiary must not be 0 address"
        );
        beneficiary = _beneficiary;
        _initTimed();
        _setLockedToken(_lockedToken);
    }
    modifier balanceCheck() {
        if (totalToken() > lastBalance) {
            uint256 delta = totalToken() - lastBalance;
            initialBalance = initialBalance + delta;
        }
        _;
        lastBalance = totalToken();
    }
    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "LinearTokenTimelock: Caller is not a beneficiary"
        );
        _;
    }
    function release(address to, uint256 amount) external override onlyBeneficiary balanceCheck {
        require(amount != 0, "LinearTokenTimelock: no amount desired");
        uint256 available = availableForRelease();
        require(amount <= available, "LinearTokenTimelock: not enough released tokens");
        _release(to, amount);
    }
    function releaseMax(address to) external override onlyBeneficiary balanceCheck {
        _release(to, availableForRelease());
    }
    function totalToken() public view override virtual returns (uint256) {
        return lockedToken.balanceOf(address(this));
    }
    function alreadyReleasedAmount() public view override returns (uint256) {
        return initialBalance - totalToken();
    }
    function availableForRelease() public view override returns (uint256) {
        uint256 elapsed = timeSinceStart();
        uint256 _duration = duration;
        uint256 totalAvailable = initialBalance * elapsed / _duration;
        uint256 netAvailable = totalAvailable - alreadyReleasedAmount();
        return netAvailable;
    }
    function setPendingBeneficiary(address _pendingBeneficiary)
        public
        override
        onlyBeneficiary
    {
        pendingBeneficiary = _pendingBeneficiary;
        emit PendingBeneficiaryUpdate(_pendingBeneficiary);
    }
    function acceptBeneficiary() public override virtual {
        _setBeneficiary(msg.sender);
    }
    function _setBeneficiary(address newBeneficiary) internal {
        require(
            newBeneficiary == pendingBeneficiary,
            "LinearTokenTimelock: Caller is not pending beneficiary"
        );
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary);
        pendingBeneficiary = address(0);
    }
    function _setLockedToken(address tokenAddress) internal {
        lockedToken = IERC20(tokenAddress);
    }
    function _release(address to, uint256 amount) internal {
        lockedToken.transfer(to, amount);
        emit Release(beneficiary, to, amount);
    }
}